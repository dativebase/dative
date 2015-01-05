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

    # WARN: THIS DOES NOT WORK!
    # The CSS *does* change dynamically, however for some unknown reason the
    # selectmenus are all screwed up after the change.
    changeThemeCSS: (event) ->
      newJQueryUICSS = @$(event.target).find(':selected').val()
      $('#jquery-ui-css').attr href: newJQueryUICSS

    initialize: ->
      @serversView = new ServersView
        collection: @model.get('servers')
        serverTypes: @model.get('serverTypes')
      @activeServerView = new ActiveServerView model: @model

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

    render: ->
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

      @pageBody.perfectScrollbar()

      @selectmenuify()
      @hoverStateFieldDisplay() # make data display react to focus & hover
      @tabindicesNaught() # active elements have tabindex=0

      @$('div.server-config-widget-body').hide()

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

    _rememberTarget: (event) ->
      try
        @$('button, .ui-selectmenu-button, input').each (index, el) =>
          if el is event.target
            @focusedElementIndex = index
            return false # break out of jQuery each loop

    setFocus: (viewType) ->
      if @focusedElementIndex?
        @$('button, .ui-selectmenu-button, input').eq(@focusedElementIndex)
          .focus().select()
      else
        @$('.ui-selectmenu-button').first().focus()

    # Alter the scroll position so that the focused UI element is centered.
    scrollToFocusedInput: (event) ->
      # Small bug: if you tab really fast through the inputs, the scroll
      # animations will be queued and all jumpy. Calling `.stop` as below
      # does nof fix the issue.
      # @$('input, button, .ui-selectmenu-button').stop('fx', true, false)

      $element = $ event.currentTarget

      # Get the true offset of the element
      initialScrollTop = @pageBody.scrollTop()
      @pageBody.scrollTop 0
      trueOffset = $element.offset().top
      @pageBody.scrollTop initialScrollTop

      windowHeight = $(window).height()
      desiredOffset = windowHeight / 2
      scrollTop = trueOffset - desiredOffset
      @pageBody.animate {scrollTop: scrollTop}, 250

