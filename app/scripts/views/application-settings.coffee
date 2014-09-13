define [
  'backbone'
  './../templates'
  './base'
  './application-settings-view'
  './application-settings-edit'
], (Backbone, JST, BaseView, ApplicationSettingsDisplayView,
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
      'keydown .dative-input': '_keyboardControl'
      'keydown .input-display': '_keyboardControl'

    initialize: ->
      @displayView = new ApplicationSettingsDisplayView model: @model
      @editView = new ApplicationSettingsEditView model: @model
      @listenTo Backbone, 'applicationSettings:edit', @edit
      @listenTo Backbone, 'applicationSettings:view', @view
      @listenTo Backbone, 'applicationSettings:save', @save
      @listenTo @model, 'change', @view

    render: ->
      @$el.html @template headerTitle: 'Application Settings'
      @displayView.setElement @$('#dative-page-body')
      @editView.setElement @$('#dative-page-body')
      @view()
      @_guify()
      @_viewButtons()

    # Render display view, close edit view
    view: ->
      @editView.close()
      @closed @editView
      @displayView.render()
      @rendered @displayView
      @_viewButtons()
      @_setFocus 'view'

    # Render edit view, close display view
    edit: (event) ->
      @_rememberClickedElement()
      @displayView.close()
      @closed @displayView
      @editView.render()
      @rendered @editView
      @_editButtons()
      @_setFocus 'edit'

    # Save to localStorage, render display view
    save: (event) ->
      applicationSettingsObject = @_getModelObjectFromForm()
      @model.save applicationSettingsObject
      @view()

    # Extract data in the inputs of the HTML "Add a Form" form and
    # convert them to an object
    _getModelObjectFromForm: ->
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

    _keyboardControl: (event) ->
      console.log "in kb contr with #{event.which}"
      # <Esc> on input field calls `view`
      if event.which is 27
        try
          class_ = $(event.target).attr 'class'
          if /dative-input/.test class_
            event.stopPropagation()
            @view()
        catch error
      # <Enter> on input calls `save`, on data display calls `edit`
      else if event.which is 13
        event.preventDefault()
        event.stopPropagation()
        try
          class_ = $(event.target).attr 'class'
          if /input-display/.test class_
            event.preventDefault()
            event.stopPropagation()
            @edit()
          else if /dative-input/.test class_
            @save()

    _rememberClickedElement: ->
      try
        @$('ul.fieldset li').each (index, el) =>
          if $.contains el, event.target
            @focusedElementIndex = index

    _guify: ->
      @$('button.edit').button()
      @$('button.view').button()
      @$('button.save').button()

    _setFocus: (viewType) ->
      if @focusedElementIndex
        @$('ul.fieldset li').eq(@focusedElementIndex).find('input')
          .first().focus().select()
      else
        if viewType is 'view'
          @$('button.edit').first().focus()
        else if viewType is 'edit'
          @$('input').first().focus()


