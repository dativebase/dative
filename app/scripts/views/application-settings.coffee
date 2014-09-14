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
      'click .dative-display': 'clickEdit'
      'click button.edit': 'clickEdit'
      'click button.save': 'clickSave'
      'click button.view': 'clickView'
      'keydown .dative-input': '_keyboardControl'
      'keydown .dative-display': '_keyboardControl'
      'keydown button': '_keyboardControl'

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

    # Render display view, close edit view
    view: ->
      @editView.close()
      @closed @editView
      @displayView.render()
      @rendered @displayView
      @_guify()
      @_viewButtons()
      @_setFocus 'view'

    clickView: (event) ->
      event.preventDefault()
      event.stopPropagation()
      @view()

    # Render edit view, close display view
    edit: ->
      @displayView.close()
      @closed @displayView
      @editView.render()
      @rendered @editView
      @_guify()
      @_editButtons()
      @_setFocus 'edit'

    clickEdit: (event) ->
      @_rememberTarget event
      event.preventDefault()
      event.stopPropagation()
      @edit()

    # Save to localStorage, render display view
    save: ->
      applicationSettingsObject = @_getModelObjectFromForm()
      @model.save applicationSettingsObject
      @view()

    clickSave: (event) ->
      event.preventDefault()
      event.stopPropagation()
      @save()

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

    _guify: ->
      @$('button').button().attr('tabindex', '1')
      @$('select, input, textarea, div.dative-display')
        .css("border-color", ApplicationSettingsView.jQueryUIColors.defBo)
        .attr('tabindex', '1')
      @$('div.dative-display')
        .mouseover(-> $(@).addClass('ui-state-hover').addClass('ui-state-active'))
        .focus(-> $(@).addClass('ui-state-hover').addClass('ui-state-active'))
        .mouseout(-> $(@).removeClass('ui-state-hover').removeClass('ui-state-active'))
        .blur(-> $(@).removeClass('ui-state-hover').removeClass('ui-state-active'))

    _rememberTarget: (event) ->
      try
        @$('.dative-input-display').each (index, el) =>
          if el is event.target
            @focusedElementIndex = index

    _setFocus: (viewType) ->
      if @focusedElementIndex?
        nthElement = @$('.dative-input-display').eq @focusedElementIndex
        nthElement.focus().select()
      else
        if viewType is 'view'
          @$('button.edit').first().focus()
        else if viewType is 'edit'
          @$('input').first().focus().select()


