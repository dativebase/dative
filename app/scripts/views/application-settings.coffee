define [
  'backbone'
  './base'
  './application-settings-view'
  './application-settings-edit'
  './../templates/application-settings-header'
  'perfectscrollbar'
], (Backbone, BaseView, ApplicationSettingsDisplayView,
  ApplicationSettingsEditView, applicationSettingsHeaderTemplate) ->

  # Application Settings View
  # -------------------------

  class ApplicationSettingsView extends BaseView

    tagName: 'div'
    template: applicationSettingsHeaderTemplate

    events:
      'click .dative-input-display.dative-display': 'clickEdit'
      'click button.edit': 'clickEdit'
      'click button.save': 'clickSave'
      'click button.view': 'clickView'
      'keydown .dative-input-display': '_keyboardControl'
      'keydown button': '_keyboardControl'
      'selectmenuchange .serverType': '_corpusSelectVisibility'

    initialize: ->
      @displayView = new ApplicationSettingsDisplayView model: @model
      @editView = new ApplicationSettingsEditView model: @model
      @listenTo Backbone, 'applicationSettings:edit', @edit
      @listenTo Backbone, 'applicationSettings:view', @view
      @listenTo Backbone, 'applicationSettings:save', @save
      @listenTo @model, 'change', @view

    render: ->
      @$el.html @template headerTitle: 'Application Settings'
      @matchHeights()
      @_body = @$ '#dative-page-body'
      @displayView.setElement @_body
      @editView.setElement @_body
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
      @_populateSelectFields()
      @_guify()
      @_addModel()
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
      @model.set applicationSettingsObject
      @model.save applicationSettingsObject

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

    _populateSelectFields: ->
      for serverType in ['LingSync', 'OLD']
        @$('select[name="serverType"]', @_body)
          .append($('<option>').attr('value', serverType).text(serverType))

    _guify: ->

      # Franklin could button buttons and perfectScrollbar.
      @$('button').button().attr('tabindex', '0')
      @_body.perfectScrollbar()

      @_selectmenuify()
      @_hoverStateFieldDisplay() # make data display react to focus & hover
      @_tabindicesNaught() # active elements have tabindex=0
      @_toggleCorpusSelect() # corpora only displayed for LingSync

    _selectmenuify: ->
      @$('select', @_body).selectmenu()
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
        .attr('tabindex', '0')


    # Only display corpus select for LingSync
    _toggleCorpusSelect: ->
      if @model.get('serverType') is 'LingSync'
        @$('li.corpusSelect').show()
      else
        @$('li.corpusSelect').hide()

    _addModel: ->
      @$('select[name="serverType"]', @_body)
        .val(@model.get('serverType'))
        .selectmenu 'refresh', true

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

    _corpusSelectVisibility: (event, ui) ->
      if ui.item.value is 'LingSync'
        @$('li.corpusSelect').slideDown('medium')
      else
        @$('li.corpusSelect').slideUp('medium')

