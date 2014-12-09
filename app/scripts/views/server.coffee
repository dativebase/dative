define [
  'backbone'
  './base'
  './../templates/server'
], (Backbone, BaseView, serverTemplate) ->

  # Server View
  # ------------

  class ServerView extends BaseView

    template: serverTemplate

    initialize: (options) ->
      @serverTypes = options.serverTypes

    events:
      'keydown button.delete-server': '_keyboardControl'
      'click button.delete-server': '_deleteServer'

    setModelFromGUI: ->
      @$('input, select').each (index, element) =>
        @model.set $(element).attr('name'), $(element).val()

    render: ->
      context = _.extend @model.attributes, serverTypes: @serverTypes
      @$el.html @template(context)
      @_guify()
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

      @$('button').button().attr('tabindex', '0')

      @$('button.delete-server')
        .button
          icons: {primary: 'ui-icon-trash'}
          text: false

      @$('button.save-server')
        .button
          icons: {primary: 'ui-icon-disk'},
          text: false

      @_selectmenuify()
      @_tabindicesNaught() # active elements have tabindex=0

      #@_hoverStateFieldDisplay() # make data display react to focus & hover

    _selectmenuify: ->
      @$('select').selectmenu width: 300
      @$('.ui-selectmenu-button').addClass 'dative-input dative-input-display'

    # Tabindices=0 and jQueryUI colors
    _tabindicesNaught: ->
      @$('select, input')
        .css("border-color", @constructor.jQueryUIColors.defBo)
        .attr('tabindex', '0')

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

