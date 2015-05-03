define [
  './form-base'
  './form-previous-version'
  './../models/form'
], (FormBaseView, FormPreviousVersionView, FormModel) ->

  # Form View
  # ---------
  #
  # For displaying individual forms.

  class FormView extends FormBaseView

    initialize: (options) ->
      super
      @events['click .resource-history'] = 'fetchHistory'
      @headerAlwaysVisible = false
      @historyFetched = false
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

    # Tell the model to fetch its history, i.e., previous versions of itself.
    fetchHistory: ->
      @disableHistoryButton()
      if @previousVersionsIsEmpty()
        try
          @model.fetchHistory()
        catch
          @enableHistoryButton()
      else
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

    previousVersionsIsEmpty: ->
      @$('div.resource-previous-versions').is ':empty'

    emptyPreviousVersions: ->
      @$('div.resource-previous-versions').empty()

    disableHistoryButton: -> @$('.resource-history').button 'disable'

    enableHistoryButton: -> @$('.resource-history').button 'enable'

    fetchHistoryFormStart: ->
      @spin()

    fetchHistoryFormEnd: ->
      @enableHistoryButton()
      @stopSpin()

    fetchHistoryFormFail: ->
      Backbone.trigger 'fetchHistoryFormFail', @model

    fetchHistoryFormSuccess: (responseJSON) ->
      if responseJSON.previous_versions.length
        @previousVersionModels =
          ((new FormModel(pv)) for pv in responseJSON.previous_versions)
        @previousVersionViews =
          ((new FormPreviousVersionView(model: fm)) for fm in @previousVersionModels)
        container = document.createDocumentFragment()
        for previousVersionView in @previousVersionViews
          container.appendChild previousVersionView.render().el
          @rendered previousVersionView
        @$('div.resource-previous-versions')
          .append container
          .hide()
          .slideDown()
      else
        Backbone.trigger 'fetchHistoryFormFailNoHistory', @model

