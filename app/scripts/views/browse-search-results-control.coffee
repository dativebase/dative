define [
  './base'
  './../models/form'
  './../utils/globals'
  './../templates/button-control'
], (BaseView, FormModel, globals, buttonControlTemplate) ->

  # Browse Search Results Control View
  # ---------------------------------
  #
  # View for a control that is a button that, when clicked, requests that the
  # forms be searched using this view's form search model, after which the user
  # is brought to a browse interface over the search results.

  class BrowseSearchResultsControlView extends BaseView

    template: buttonControlTemplate
    className: 'browse-search-results-control-view control-view dative-widget-center'

    initialize: (options) ->
      @formModel = new FormModel()
      @resourceName = options?.resourceName or 'formSearch'
      @activeServerType = @getActiveServerType()
      @listenToEvents()

    events:
      'click button.search':         'search'

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
        buttonClass: 'search'
        buttonTitle: "Click this button to perform this search and then browse
          through the forms that it captures."
        buttonText: 'Browse search results'
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

    search: ->
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


