define [
  'backbone'
  './base'
  './../templates/server'
], (Backbone, BaseView, serverTemplate) ->

  # Server View
  # ------------

  class ServerView extends BaseView

    tagName: 'div'
    className: "server-config-widget dative-widget-center ui-widget ui-widget-content ui-corner-all"
    template: serverTemplate

    #initialize: ->
    #  @listenTo @model, 'remove', @_destroyModelView

    _destroyModelView: ->
      console.log 'want to destroy this view'

    events:
      'keydown button.delete-server': '_keyboardControl'
      'click button.delete-server': '_deleteServer'

    _getFormData: ->
      formData = {}
      #@$(selector).val() for selector in ['input[name=name]', 'input[name=url]', 'select[name=type]']
      @$('input, select').each ->
        # console.log 'have an input'
        # console.log $(@).val()
        formData[$(@).attr('name')] = $(@).val()
      formData


    render: ->
      # TODO: the template needs to know the possible server types ...
      @$el.html @template(@model.attributes)
      @_guify()
      @

    _deleteServer: (event) ->
      if event
        event.preventDefault()
        event.stopPropagation()
      @model.destroy()
      @$el.slideUp =>
        @remove()

    # Save to localStorage, render display view
    save: ->
      console.log 'You want to save this server model', @model.attributes
      # TODO: direct save or delegate to collection?

    # Extract data in the inputs of the HTML "Add a Form" form and
    # convert them to an object
    _getModelObjectFromForm: ->
      modelObject = {}
      for $element in @$('input, select')
        modelObject[$element.attr('name')] = 'a'
      # for fieldObject in @$('form.applicationSettingsForm').serializeArray()
      # modelObject[fieldObject.name] = fieldObject.value
      modelObject

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

