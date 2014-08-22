define [
  'jquery'
  'lodash'
  'backbone'
  'templates'
  'views/base'
  'views/application-settings-view'
  'views/application-settings-edit'
], ( $, _, Backbone, JST, BaseView, ApplicationSettingsDisplayView,
  ApplicationSettingsEditView) ->

  # Application Settings View
  # -------------------------

  class ApplicationSettingsView extends BaseView

    tagName: 'div'
    template: JST['app/scripts/templates/application-settings-header.ejs']

    events:
      'click .input-display': 'edit'
      'click button.edit': 'edit'
      'click button.save': 'save'
      'click button.view': 'view'

      'keypress #serverURL': '_keyboardControl'
      'keypress #serverPort': '_keyboardControl'
      'keypress #username': '_keyboardControl'
      'keypress #persistenceType': '_keyboardControl'
      'keypress #schemaType': '_keyboardControl'

      'keydown': '_escape'

    initialize: ->
      if not @displayView
        @displayView = new ApplicationSettingsDisplayView model: @model
      if not @editView
        @editView = new ApplicationSettingsEditView model: @model
      @listenTo Backbone, 'applicationSettings:edit', @edit
      @listenTo Backbone, 'applicationSettings:view', @view
      @listenTo Backbone, 'applicationSettings:save', @save
      @listenTo @model, 'change', @view

    # Render display view, close edit view
    view: ->
      console.log 'IN VIEW'
      @editView.close()
      @closed @editView
      @displayView.render()
      @rendered @displayView
      @_viewButtons()
      @_setFocus('view')

    # Render edit view, close display view
    edit: (event) ->
      console.log 'IN EDIT'
      #@_removeTextSelection() # remove selected text glitch (only necessary with double click event)
      @_rememberDBLClickedElement()
      @displayView.close()
      @closed @displayView
      @editView.render()
      @rendered @editView
      @_editButtons()
      @_setFocus('edit')

    # Save to localStorage, render display view
    save: (event) ->
      console.log 'IN SAVE'
      applicationSettingsObject = @getModelObjectFromApplicationSettingsForm()
      @model.save()
      @view()

    # Extract data in the inputs of the HTML "Add a Form" form and
    # convert them to an object
    getModelObjectFromApplicationSettingsForm: ->
      modelObject = {}
      for fieldObject in @$('form.applicationSettingsForm').serializeArray()
        modelObject[fieldObject.name] = fieldObject.value
      modelObject

    _editButtons: ->
      @$('button.edit').hide()
      @$('button.view').show()
      @$('button.save').show()

    _viewButtons: ->
      @$('button.edit').show()
      @$('button.view').hide()
      @$('button.save').hide()

    _escape: (event) ->
      if event.which is 27 and @editView in @_renderedSubViews
        @view()

    _keyboardControl: (event) ->
      console.log 'keypress'
      if event.which is 27
        try
          class_ = $(event.target).attr('class')
          console.log class_
          if /dative-input/.test(class_)
            event.stopPropagation()
            console.log 'DATIVE INPUT'
            @view()
        catch error
          console.log 'error'
      else if event.which is 13
        event.preventDefault()
        event.stopPropagation()
        try
          class_ = $(event.target).attr('class')
          if /input-display/.test(class_)
            event.preventDefault()
            event.stopPropagation()
            console.log 'INPUT DISPLAY'
            @edit()
          else if /dative-input/.test class_
            @save()

    # Remove text selection caused by double click
    _removeTextSelection: ->
      if window.getSelection
          window.getSelection().removeAllRanges()
      else if document.selection
          document.selection.empty()

    _rememberDBLClickedElement: ->
      try
        @focusedElementId = event.target.id # remember what was clicked

    render: ->
      @$el.html @template headerTitle: 'ApplicationSettings'
      @displayView.setElement '#old-page-body'
      @editView.setElement '#old-page-body'
      @view()
      @_guify()
      @_viewButtons()

    _guify: ->
      @$('button.edit').button()
      @$('button.view').button()
      @$('button.save').button()

    _setFocus: (viewType) ->
      console.log 'IN SET FOCUS'
      if @focusedElementId
        console.log 'FOCUSED ELEMENT ID'
        @$("##{@focusedElementId}").first().focus().select()
      else
        if viewType is 'view'
          console.log 'FOCUSING THE EDIT BUTTON'
          $('button.edit').first().focus()
        else if viewType is 'edit'
          console.log 'FOCUSING THE INPUT BUTTON'
          $('input').first().focus()
        else
          console.log 'NO CONDITIONS APPLY IN FOCUS'
          console.log @_renderedSubViews


