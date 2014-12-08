define [
  'backbone'
  './base'
  './servers'
  './../templates/application-settings'
  'perfectscrollbar'
], (Backbone, BaseView, ServersView, applicationSettingsTemplate) ->

  # Application Settings View
  # -------------------------

  class ApplicationSettingsView extends BaseView

    tagName: 'div'
    template: applicationSettingsTemplate

    events:
      'click button.save': 'clickSave'
      'keydown .dative-input-display': '_keyboardControl'
      'keydown button': '_keyboardControl'
      'selectmenuchange .serverType': '_corpusSelectVisibility'

    initialize: ->
      @serversView = new ServersView collection: @model.get('servers')
      @listenTo Backbone, 'applicationSettings:edit', @edit
      @listenTo Backbone, 'applicationSettings:view', @view
      @listenTo Backbone, 'applicationSettings:save', @save
      @listenTo @model, 'change', @view

    render: ->
      params = _.extend {headerTitle: 'Application Settings'}, @model.attributes
      @$el.html @template(params)

      @serversView.setElement(@$('li.server-config-container').first()).render()
      @rendered @serversView

      @matchHeights()
      @pageBody = @$ '#dative-page-body'
      @_guify()

    save: ->
      # Will always be considered new since it has no id attribute
      console.log "ApplicationSettingsModel is new? #{@model.isNew()}"
      @model.save @_getFormData()

    clickSave: (event) ->
      event.preventDefault()
      event.stopPropagation()
      @save()

    _getFormData: ->
      #activeServer: @$('select[name=activeServer]').val()
      activeServer: @model.get('servers').findWhere(
        url: @$('select[name=activeServer]').val())
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

      @$('button').button().attr('tabindex', '0')

      @$('.dative-page-header-title').first()
        .position
          of: @$('.dative-page-header-title').first().parent()

      # Main Page GUIfication

      @$('button.edit').button({icons: {primary: 'ui-icon-pencil'}, text:
        false})
      @$('button.save').button({icons: {primary: 'ui-icon-disk'}, text: false})

      @pageBody.perfectScrollbar()

      @_selectmenuify()
      @_hoverStateFieldDisplay() # make data display react to focus & hover
      @_tabindicesNaught() # active elements have tabindex=0
      @_toggleCorpusSelect() # corpora only displayed for FieldDB

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
        .attr('tabindex', '0')

    # Only display corpus select for FieldDB
    _toggleCorpusSelect: ->
      if @model.get('serverType') is 'FieldDB'
        @$('li.corpusSelect').show()
      else
        @$('li.corpusSelect').hide()

    _addModel: ->
      @$('select[name="serverType"]', @pageBody)
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
      if ui.item.value is 'FieldDB'
        @$('li.corpusSelect').slideDown('medium')
      else
        @$('li.corpusSelect').slideUp('medium')

