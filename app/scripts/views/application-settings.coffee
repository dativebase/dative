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
      'click button.save': 'clickSave'
      'keydown .dative-input-display': '_keyboardControl'
      'keydown button': '_keyboardControl'
      'keyup input': 'setModelFromGUI'
      'selectmenuchange': 'setModelFromGUI'
      'click': 'setModelFromGUI'

      'focus input': 'scrollToFocusedInput'
      'focus button': 'scrollToFocusedInput'
      # BUG: if you scroll to a selectmenu you've just clicked on, the select
      # dropdown will be left hanging in the place where you originally
      # clicked it. So I've disabled "scroll-to-focus" for selectmenus for now.
      #'focus .ui-selectmenu-button': 'scrollToFocusedInput'

    initialize: ->
      @serversView = new ServersView
        collection: @model.get('servers')
        serverTypes: @model.get('serverTypes')
      @activeServerView = new ActiveServerView model: @model

    listenToEvents: ->
      @listenTo Backbone, 'applicationSettings:edit', @edit
      @listenTo Backbone, 'applicationSettings:view', @view
      @listenTo Backbone, 'applicationSettings:save', @save
      if @model.get('activeServer')
        @listenTo @model.get('activeServer'), 'change:url', @activeServerURLChanged
      @delegateEvents()

    activeServerURLChanged: ->
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
      @_guify()
      @_setFocus()
      @listenToEvents()
      @

    clickSave: (event) ->
      event.preventDefault()
      event.stopPropagation()
      @save()

    save: ->
      @setModelFromGUI()
      @model.save()

    setModelFromGUI: ->
      @model.set 'activeServer', @$('select[name=activeServer]').val()
      @serversView.setCollectionFromGUI()

    _getFormData: ->
      #activeServer: @$('select[name=activeServer]').val()

      activeServer: @model.get('servers').findWhere(
        id: @$('select[name=activeServer]').val())
      servers: @serversView._getFormData()

    _editButtons: ->
      @$('button.edit').button 'disable'
      @$('button.save').button 'enable'
      #@$('button.view').show()

    _viewButtons: ->
      @$('button.edit').button 'enable'
      @$('button.save').button 'disable'
      #@$('button.view').hide()

    _keyboardControl: (event) ->
      @_rememberTarget event
      # <Esc> on input field calls `view`
      if event.which is 27
        try
          classes = $(event.target).attr('class').split /\s+/
          if 'dative-input' in classes
            event.stopPropagation()
            @view()
        catch error
      # <Enter> on input calls `save`, on data display calls `edit`
      else if event.which is 13
        event.preventDefault()
        event.stopPropagation()
        try
          classes = $(event.target).attr('class').split /\s+/
          if 'dative-display' in classes
            @edit()
          else if 'dative-input' in classes
            @save()
          else if 'view' in classes
            @view()
          else if 'edit' in classes
            @edit()
          else if 'save' in classes
            @save()
          else if 'add-server' in classes
            @_addServer()

    _populateSelectFields: ->
      for serverType in ['FieldDB', 'OLD']
        @$('select[name="serverType"]', @pageBody)
          .append($('<option>').attr('value', serverType).text(serverType))

    _guify: ->

      @$('button').button().attr('tabindex', 0)

      # Main Page GUIfication

      @$('button.edit').button({icons: {primary: 'ui-icon-pencil'}, text:
        false})
      @$('button.save').button({icons: {primary: 'ui-icon-disk'}, text: false})

      @pageBody.perfectScrollbar()

      @_selectmenuify()
      @_hoverStateFieldDisplay() # make data display react to focus & hover
      @_tabindicesNaught() # active elements have tabindex=0

      @$('div.server-config-widget-body').hide()

    _selectmenuify: ->
      @$('select', @pageBody).selectmenu()
      @$('.ui-selectmenu-button').addClass 'dative-input dative-input-display'

    # Make active elements have tabindex=0
    _hoverStateFieldDisplay: ->
      @$('div.dative-input-display')
        .mouseover(->
          $(@).addClass('ui-state-hover').addClass('ui-state-active'))
        .focus(-> $(@).addClass('ui-state-hover').addClass('ui-state-active'))
        .mouseout(->
          $(@).removeClass('ui-state-hover').removeClass('ui-state-active'))
        .blur(->
          $(@).removeClass('ui-state-hover').removeClass('ui-state-active'))

    # Tabindices=0 and jQueryUI colors
    _tabindicesNaught: ->
      @$('button, select, input, textarea, div.dative-input-display,
        span.ui-selectmenu-button')
        .css("border-color", ApplicationSettingsView.jQueryUIColors.defBo)
        .attr('tabindex', 0)

    _addModel: ->
      @$('select[name="serverType"]', @pageBody)
        .val(@model.get('serverType'))
        .selectmenu 'refresh', true

    _rememberTarget: (event) ->
      try
        @$('button, .ui-selectmenu-button, input').each (index, el) =>
          if el is event.target
            @focusedElementIndex = index
            return false # break out of jQuery each loop

    _setFocus: (viewType) ->
      if @focusedElementIndex?
        #@$('.dative-input-display').eq(@focusedElementIndex)
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

