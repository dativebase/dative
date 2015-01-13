define [
  'backbone'
  './base'
  './servers'
  './active-server'
  './../templates/application-settings'
  'perfectscrollbar'
], (Backbone, BaseView, ServersView, ActiveServerView, applicationSettingsTemplate) ->

  # Application Settings View
  # -------------------------

  class ApplicationSettingsView extends BaseView

    tagName: 'div'
    template: applicationSettingsTemplate

    events:
      'keyup input': 'setModelFromGUI'
      'selectmenuchange': 'setModelFromGUI'
      'click': 'setModelFromGUI'
      'focus input': 'scrollToFocusedInput'
      'focus button': 'scrollToFocusedInput'
      # BUG: if you scroll to a selectmenu you've just clicked on, the select
      # dropdown will be left hanging in the place where you originally
      # clicked it. So I've disabled "scroll-to-focus" for selectmenus for now.
      #'focus .ui-selectmenu-button': 'scrollToFocusedInput'
      'selectmenuchange select[name=css-theme]': 'changeThemeCSS'
      'focus button, input, .ui-selectmenu-button': 'rememberFocusedElement'

    # WARN: THIS DOES NOT WORK!
    # The CSS *does* change dynamically, however for some unknown reason the
    # selectmenus are all screwed up after the change.
    changeThemeCSS: (event) ->
      newJQueryUICSS = @$(event.target).find(':selected').val()
      $('#jquery-ui-css').attr href: newJQueryUICSS

    initialize: ->
      @focusedElementIndex = null
      @serversView = new ServersView
        collection: @model.get('servers')
        serverTypes: @model.get('serverTypes')
      @activeServerView = new ActiveServerView
        model: @model
        tooltipPosition:
          my: "right-100 center"
          at: "left center"
          collision: "flipfit"

    listenToEvents: ->
      @listenTo Backbone, 'activateServer', @activateServer
      @listenTo Backbone, 'removeServerView', @setModelFromGUI
      if @model.get('activeServer')
        @listenTo @model.get('activeServer'), 'change:url', @activeServerURLChanged
      @delegateEvents()

    activateServer: (id) ->
      @$('select[name=activeServer]')
        .val(id)
        .selectmenu('refresh')
      @setModelFromGUI()

    activeServerURLChanged: ->
      # TODO @jrwdunham: what is the point of this method? Delete or use...
      #console.log 'active server url has changed'
      return

    render: (taskId) ->
      params = _.extend {headerTitle: 'Application Settings'}, @model.attributes
      @$el.html @template(params)

      @serversView.setElement @$('li.server-config-container').first()
      @activeServerView.setElement @$('li.active-server').first()

      @serversView.render()
      @activeServerView.render()

      @rendered @serversView
      @rendered @activeServerView

      @matchHeights()
      @pageBody = @$ '#dative-page-body'
      @guify()
      @setFocus()
      @listenToEvents()
      Backbone.trigger 'longTask:deregister', taskId
      @

    setModelFromGUI: ->
      @model.set 'activeServer', @$('select[name=activeServer]').val()
      @serversView.setCollectionFromGUI()
      @model.save()

    guify: ->

      @$('button').button().attr('tabindex', 0)

      # Main Page GUIfication

      @$('button.edit').button({icons: {primary: 'ui-icon-pencil'}, text:
        false})
      @$('button.save').button({icons: {primary: 'ui-icon-disk'}, text: false})

      @perfectScrollbar()

      @selectmenuify()
      @hoverStateFieldDisplay() # make data display react to focus & hover
      @tabindicesNaught() # active elements have tabindex=0

      @$('div.server-config-widget-body').hide()

    perfectScrollbar: ->
      @$('div#dative-page-body').first()
        .perfectScrollbar()
        .scroll => @closeAllTooltips()

    # The special `onClose` event is called by `close` in base.coffee upon close
    onClose: ->
      @$('div#dative-page-body').first().unbind 'scroll'

    selectmenuify: ->
      @$('select', @pageBody).selectmenu()
      @$('.ui-selectmenu-button').addClass 'dative-input dative-input-display'

    # Make active elements have tabindex=0
    hoverStateFieldDisplay: ->
      @$('div.dative-input-display')
        .mouseover(->
          $(@).addClass('ui-state-hover').addClass('ui-state-active'))
        .focus(-> $(@).addClass('ui-state-hover').addClass('ui-state-active'))
        .mouseout(->
          $(@).removeClass('ui-state-hover').removeClass('ui-state-active'))
        .blur(->
          $(@).removeClass('ui-state-hover').removeClass('ui-state-active'))

    # Tabindices=0 and jQueryUI colors
    tabindicesNaught: ->
      @$('button, select, input, textarea, div.dative-input-display,
        span.ui-selectmenu-button')
        .css("border-color", ApplicationSettingsView.jQueryUIColors.defBo)
        .attr('tabindex', 0)

    setFocus: ->
      if @focusedElementIndex
        @focusLastFocusedElement()
      else
        @focusFirstElement()

