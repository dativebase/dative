define [
  './form-base'
  './form-previous-version'
  './../models/form'
], (FormBaseView, FormPreviousVersionView, FormModel) ->

  # Form View
  # ---------
  #
  # For displaying individual forms.
  #
  # Most form-relevant logic is in `FormBaseView`, which is also sublcassed by
  # `FormPreviousVersionView`. Only `FormView` has logic for fetching and
  # displaying previous versions.

  class FormView extends FormBaseView

    initialize: (options) ->
      super
      @events['click .resource-history'] = 'toggleHistory'
      @headerAlwaysVisible = false
      @previousVersionModels = []
      @previousVersionViews = []

    # We don't want forms to have header titles.
    getHeaderTitle: -> ''

    # Forms have histories, so we remove 'history' from the excluded actions.
    excludedActions: []

    listenToEvents: ->
      super
      @listenToFetchHistoryEvents()

    listenToFetchHistoryEvents: ->
      @listenTo @model, "fetchHistoryFormStart", @fetchHistoryFormStart
      @listenTo @model, "fetchHistoryFormEnd", @fetchHistoryFormEnd
      @listenTo @model, "fetchHistoryFormFail", @fetchHistoryFormFail
      @listenTo @model, "fetchHistoryFormSuccess", @fetchHistoryFormSuccess

    # Show or hide the previous versions, depending on whether there are any
    # previous versions currently visible.
    toggleHistory: ->
      @disableHistoryButton()
      if @previousVersionsIsEmpty()
        try
          @model.fetchHistory()
        catch
          @enableHistoryButton()
      else
        @undiffThis()
        @destroyPreviousVersions()

    # Destroy any present previous versions: hide dome stuff, delete models,
    # close views.
    destroyPreviousVersions: ->
      @hidePreviousVersionsAnimate()
      @previousVersionModels = []
      for previousVersionView in @previousVersionViews
        previousVersionView.close()
        @closed previousVersionView

    hidePreviousVersionsAnimate: ->
      @$('div.resource-previous-versions').slideUp
        complete: =>
          @enableHistoryButton()
          @emptyPreviousVersions()
          @setHistoryButtonStateEmpty()

    previousVersionsIsEmpty: ->
      @$('div.resource-previous-versions').is ':empty'

    emptyPreviousVersions: -> @$('div.resource-previous-versions').empty()

    disableHistoryButton: -> @$('.resource-history').button 'disable'

    setHistoryButtonStateEmpty: ->
      @$('.resource-history')
        .tooltip
          items: 'button'
          content: 'view the history of this form'

    setHistoryButtonStateNotEmpty: ->
      @$('.resource-history')
        .tooltip
          items: 'button'
          content: 'hide the history of this form'

    enableHistoryButton: -> @$('.resource-history').button 'enable'

    fetchHistoryFormStart: -> @spin()

    fetchHistoryFormEnd: ->
      @enableHistoryButton()
      @stopSpin()

    fetchHistoryFormFail: ->
      Backbone.trigger 'fetchHistoryFormFail', @model

    # We have successfully requested previous versions, so we create models and
    # views and display them.
    fetchHistoryFormSuccess: (responseJSON) ->
      if responseJSON.previous_versions.length
        @previousVersionModels =
          ((new FormModel(pv)) for pv in responseJSON.previous_versions)
        @comparatorModel = @previousVersionModels[0]
        @diffThis()
        @previousVersionViews = []
        for formModel, index in @previousVersionModels
          nextIndex = index + 1
          if nextIndex is @previousVersionModels.length
            nextFormModel = null
          else
            nextFormModel = @previousVersionModels[nextIndex]
          formView = new FormPreviousVersionView
            model: formModel
            comparatorModel: nextFormModel
            expanded: @secondaryDataVisible
            dataLabelsVisible: @dataLabelsVisible
          @previousVersionViews.push formView
        container = document.createDocumentFragment()
        for previousVersionView in @previousVersionViews
          container.appendChild previousVersionView.render().el
          @rendered previousVersionView
        @$('div.resource-previous-versions')
          .append container
          .hide()
          .slideDown
            complete: => @setHistoryButtonStateNotEmpty()
      else
        Backbone.trigger 'fetchHistoryFormFailNoHistory', @model

