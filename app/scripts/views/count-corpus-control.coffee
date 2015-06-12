define [
  './base'
  './../models/form'
  './../utils/globals'
  './../templates/button-control'
], (BaseView, FormModel, globals, buttonControlTemplate) ->

  # Count Corpus Control View
  # -------------------------
  #
  # View for a control that is a button that, when clicked, requests that the
  # number of forms in this view's corpus be displayed.

  class CountCorpusControlView extends BaseView

    template: buttonControlTemplate
    className: 'count-corpus-control-view control-view
      dative-widget-center'

    initialize: (options) ->
      @formModel = new FormModel()
      @resourceName = options?.resourceName or 'formSearch'
      @activeServerType = @getActiveServerType()
      @listenToEvents()

    events:
      'click button.count-corpus':         'countCorpus'

    listenToEvents: ->
      super
      @listenTo @formModel, "searchStart", @searchStart
      @listenTo @formModel, "searchEnd", @searchEnd
      @listenTo @formModel, "searchFail", @searchFail
      @listenTo @formModel, "searchSuccess", @searchSuccess

    controlSummaryClass: 'corpus-count-summary'
    controlResultsClass: 'corpus-count-results'
    controlResults: ''
    getControlSummary: -> ''

    buttonClass: 'count-corpus'

    html: ->
      context =
        buttonClass: @buttonClass
        buttonTitle: "Click this button to see how many forms are in this
          corpus."
        buttonText: 'Count corpus'
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

    countCorpus: ->
      search =
        filter: ["Form", "corpora", "id", "in", [@model.get('id')]]
        order_by: ["Form", "id", "desc" ]
      @formModel.search search

    searchStart: ->
      @$(".#{@controlSummaryClass}").html ''
      @spin "button.#{@buttonClass}", '50%', '135%'
      @disableCountButton()

    searchEnd: ->
      @stopSpin "button.#{@buttonClass}"
      @enableCountButton()

    searchFail: (error) ->
      Backbone.trigger "corpusCountFail", error, @model.get('id')

    searchSuccess: (responseJSON) ->
      @$(".#{@controlSummaryClass}").html(
        "#{@utils.integerWithCommas(responseJSON.paginator.count)} forms are in
        this corpus.")
      Backbone.trigger "corpusCountSuccess", @model.get('id')

    disableCountButton: ->
      @$("button.#{@buttonClass}").button 'disable'

    enableCountButton: ->
      @$("button.#{@buttonClass}").button 'enable'


