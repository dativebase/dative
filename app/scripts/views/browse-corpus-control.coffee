define [
  './base'
  './../models/form'
  './../utils/globals'
  './../templates/button-control'
], (BaseView, FormModel, globals, buttonControlTemplate) ->

  # Browse Corpus Control View
  # --------------------------
  #
  # View for a control that is a button that, when clicked, requests that the
  # forms be searched using this view's form search model, after which the user
  # is brought to a browse interface over the search results.

  class BrowseCorpusControlView extends BaseView

    template: buttonControlTemplate
    className: 'browse-corpus-control-view control-view dative-widget-center'

    initialize: (options) ->
      @formModel = new FormModel()
      @resourceName = options?.resourceName or 'formSearch'
      @activeServerType = @getActiveServerType()
      @listenToEvents()

    events:
      'click button.browse-corpus':         'browseCorpus'

    listenToEvents: ->
      super
      @listenTo @formModel, "searchStart", @searchStart
      @listenTo @formModel, "searchEnd", @searchEnd
      @listenTo @formModel, "searchFail", @searchFail
      @listenTo @formModel, "searchSuccess", @searchSuccess

    controlSummaryClass: 'browse-corpus-summary'
    controlResultsClass: 'browse-corpus-results'
    controlResults: ''
    getControlSummary: -> ''

    buttonClass: 'browse-corpus'

    html: ->
      context =
        buttonClass: @buttonClass
        buttonTitle: "Click this button to browse the forms in this corpus."
        buttonText: 'Browse corpus'
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

    browseCorpus: ->
      Backbone.trigger(
        'request:formsBrowseCorpus',
        corpus: @model)

    searchStart: ->
      @$(".#{@controlSummaryClass}").html ''
      @spin "button#{@buttonClass}", '50%', '135%'
      @disableSearchButton()

    searchEnd: ->
      @stopSpin "button#{@buttonClass}"
      @enableSearchButton()

    searchFail: (error) ->
      Backbone.trigger "corpusBrowseFail", error, @model.get('id')

    searchSuccess: (responseJSON) ->
      @$(".#{@controlSummaryClass}").html(
        "#{@utils.integerWithCommas(responseJSON.paginator.count)} forms match
        this search.")
      Backbone.trigger "corpusBrowseSuccess", @model.get('id')

    disableSearchButton: ->
      @$("button#{@buttonClass}").button 'disable'

    enableSearchButton: ->
      @$("button#{@buttonClass}").button 'enable'



