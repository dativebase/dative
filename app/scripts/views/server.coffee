define [
  'backbone'
  './base'
  './../templates/server'
], (Backbone, BaseView, serverTemplate) ->

  # Server View
  # ------------

  class ServerView extends BaseView

    template: serverTemplate

    initialize: ->
      @applicationSettingsModel = @model.collection.applicationSettings
      @serverTypes = @applicationSettingsModel.get 'serverTypes'
      @serverCodes = @applicationSettingsModel.get 'fieldDBServerCodes'

    events:
      'keydown button.delete-server': '_keyboardControl'
      'click button.delete-server': '_deleteServer'
      'selectmenuchange': 'toggleServerCodeSelect'

    listenToEvents: ->
      @listenTo @applicationSettingsModel, 'change:activeServer',
        @activeServerChanged
      @delegateEvents()

    toggleServerCodeSelect: ->
      if @$('select[name=type]').first().val() is 'FieldDB'
        @$('li.serverCode').slideDown()
      else
        @$('li.serverCode').slideUp()

    activeServerChanged: ->
      if @active()
        @$('.dative-widget-header-title').text 'Active Server'
        @$('.dative-widget-body').addClass 'ui-state-highlight'
      else
        @$('.dative-widget-header-title').text 'Server'
        @$('.dative-widget-body').removeClass 'ui-state-highlight'

    active: ->
      @model is @model.collection.applicationSettings.get 'activeServer'

    setModelFromGUI: ->
      @$('input, select').each (index, element) =>
        @model.set $(element).attr('name'), $(element).val()

    render: ->
      headerTitle = if @active() then 'Active Server' else 'Server'
      context = _.extend(@model.attributes
        {
          serverTypes: @serverTypes,
          serverCodes: @serverCodes,
          isActive: @active(),
          headerTitle: headerTitle
        }
      )
      @$el.html @template(context)
      @_guify()
      @listenToEvents()
      @

    _deleteServer: (event) ->
      if event
        event.preventDefault()
        event.stopPropagation()
      @$el.slideUp 'medium', =>
        @model.trigger 'removeme', @model
        Backbone.trigger 'removeServerView', @
        @remove()

    _keyboardControl: (event) ->
      @_rememberTarget event
      if event.which is 13
        event.preventDefault()
        event.stopPropagation()
        @_deleteServer()

    _populateSelectFields: ->
      for serverType in ['FieldDB', 'OLD']
        @$('select[name="serverType"]', @pageBody)
          .append($('<option>').attr('value', serverType).text(serverType))

    _guify: ->

      @$('button').button().attr('tabindex', 0)

      @$('button.delete-server')
        .button
          icons: {primary: 'ui-icon-trash'}
          text: false

      @$('button.save-server')
        .button
          icons: {primary: 'ui-icon-disk'},
          text: false

      @_selectmenuify()
      if @model.get('type') is 'OLD' then @$('li.serverCode').hide()
      @_tabindicesNaught() # active elements have tabindex=0

      #@_hoverStateFieldDisplay() # make data display react to focus & hover

    _selectmenuify: ->
      @$('select').selectmenu width: 320
      @$('.ui-selectmenu-button').addClass 'dative-input dative-input-display'

    # Tabindices=0 and jQueryUI colors
    _tabindicesNaught: ->
      @$('select, input')
        .css("border-color", @constructor.jQueryUIColors.defBo)
        .attr('tabindex', 0)

    _rememberTarget: (event) ->
      try
        @$('.dative-input-display').each (index, el) =>
          if el is event.target
            @focusedElementIndex = index

    _setFocus: (viewType) ->
      if @focusedElementIndex?
        @$('.dative-input-display').eq(@focusedElementIndex)
          .focus().select()
      else
        if viewType is 'view'
          @$('button.edit').first().focus()
        else if viewType is 'edit'
          @$('select, input').first().focus().select()

