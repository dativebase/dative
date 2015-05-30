define [
  './base'
  './../models/form'
  './../utils/globals'
  './../templates/button-control'
], (BaseView, FormModel, globals, buttonControlTemplate) ->

  # Count Search Results Control View
  # ---------------------------------
  #
  # View for a control that is a button that, when clicked, requests that the
  # forms be searched using this view's form search model and the number of
  # results of that search be displayed.

  class CountSearchResultsControlView extends BaseView

    template: buttonControlTemplate
    className: 'count-search-results-control-view control-view dative-widget-center'

    initialize: (options) ->
      @formModel = new FormModel()
      @resourceName = options?.resourceName or 'formSearch'
      @activeServerType = @getActiveServerType()
      @listenToEvents()

    events:
      'click button.count-search-results':         'countSearchResults'

    listenToEvents: ->
      super
      @listenTo @formModel, "searchStart", @searchStart
      @listenTo @formModel, "searchEnd", @searchEnd
      @listenTo @formModel, "searchFail", @searchFail
      @listenTo @formModel, "searchSuccess", @searchSuccess

    controlSummaryClass: 'search-summary'
    controlResultsClass: 'search-results'
    controlResults: ''
    getControlSummary: -> ''

    html: ->
      context =
        buttonClass: 'count-search-results'
        buttonTitle: "Click this button to perform this search and see how many
          forms it returns."
        buttonText: 'Count search results'
        controlResultsClass: @controlResultsClass
        controlSummaryClass: @controlSummaryClass
        controlResults: @controlResults
        controlSummary: @getControlSummary()
      @$el.html @template(context)

    render: ->
      @html()
      @guify()
      @listenToEvents()
      @

    guify: ->
      @buttonify()
      @tooltipify()

    tooltipify: ->
      @$('.dative-tooltip')
        .tooltip position: @tooltipPositionLeft('-20')

    spinnerOptions: (top='50%', left='-170%') ->
      options = super
      options.top = top
      options.left = left
      options.color = @constructor.jQueryUIColors().defCo
      options

    spin: (selector='.spinner-container', top='50%', left='-170%') ->
      @$(selector).spin @spinnerOptions(top, left)

    stopSpin: (selector='.spinner-container') ->
      @$(selector).spin false

    ############################################################################
    # Search
    ############################################################################

    countSearchResults: ->
      @formModel.search @model.get('search')

    searchStart: ->
      @$(".#{@controlSummaryClass}").html ''
      @spin 'button.search', '50%', '135%'
      @disableSearchButton()

    searchEnd: ->
      @stopSpin 'button.search'
      @enableSearchButton()

    searchFail: (error) ->
      Backbone.trigger "formSearchFail", error, @model.get('id')

    searchSuccess: (responseJSON) ->
      @$(".#{@controlSummaryClass}").html(
        "#{@utils.integerWithCommas(responseJSON.paginator.count)} forms match
        this search.")
      Backbone.trigger "formSearchSuccess", @model.get('id')

    disableSearchButton: ->
      @$('button.search').button 'disable'

    enableSearchButton: ->
      @$('button.search').button 'enable'

