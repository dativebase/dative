define [
  './base'
  './../utils/globals'
  './../templates/button-control'
], (BaseView, globals, buttonControlTemplate) ->

  # Search Control View
  # -------------------
  #
  # View for a control for requesting that a search be performed using the
  # form search resource that this control belongs to.

  class SearchControlView extends BaseView

    template: buttonControlTemplate
    className: 'search-control-view control-view dative-widget-center'

    initialize: (options) ->
      @resourceName = options?.resourceName or 'phonology'
      @activeServerType = @getActiveServerType()
      @listenToEvents()

    events:
      'click button.search':         'search'

    listenToEvents: ->
      super
      @listenTo @model, "searchStart", @searchStart
      @listenTo @model, "searchEnd", @searchEnd
      @listenTo @model, "searchFail", @searchFail
      @listenTo @model, "searchSuccess", @searchSuccess
      @listenTo @model, "fetchPhonologySuccess", @fetchPhonologySuccess
      @listenTo @model, "fetchPhonologyFail", @fetchPhonologyFail

    controlSummaryClass: 'search-summary'
    controlResultsClass: 'search-results'
    controlResults: ''

    getControlSummary: ->
      if @model.get('search_succeeded')
        @controlSummary = "<i class='fa fa-check boolean-icon true'></i>
          Search succeeded: #{@model.get('search_message')}"
      else
        searchAttempt = @model.get 'search_attempt'
        if searchAttempt is null
          @controlSummary = "Nobody has yet attempted to search this
            #{@resourceName}"
        else
          @controlSummary = "<i class='fa fa-times boolean-icon false'></i>
            Search failed: #{@model.get('search_message')}"

    # Write the initial HTML to the page.
    # TODO: the OLD should give us a timestamp of the last search attempt so
    # we can know whether our most recent search attempt corresponds to the
    # current state of the FST-based resource being searchd here.
    html: ->
      context =
        buttonClass: 'search'
        buttonTitle: "Click this button to request that this
          #{@resourceName}’s FST script be searched so that it can be used to
          map underlying representations to surface ones or vice versa."
        buttonText: 'Search'
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

    search: -> @model.search()

    searchStart: ->
      @$(".#{@controlSummaryClass}").html ''
      @spin 'button.search', '50%', '135%'
      @disableSearchButton()

    searchEnd: ->

    searchFail: (error) ->
      Backbone.trigger "#{@resourceName}SearchFail", error, @model.get('id')

    searchSuccess: ->
      @searchAttempt = @model.get('search_attempt')
      @poll()

    disableSearchButton: ->
      @$('button.search').button 'disable'

    enableSearchButton: ->
      @$('button.search').button 'enable'

    fetch: -> @model.fetchResource @model.get('id')

    fetchPhonologySuccess: (phonologyObject) ->
      if phonologyObject.search_attempt is @searchAttempt
        @poll()
      else
        @model.set
          search_succeeded: phonologyObject.search_succeeded
          search_attempt: phonologyObject.search_attempt
          search_message: phonologyObject.search_message
          datetime_modified: phonologyObject.datetime_modified
          modifier: phonologyObject.modifier
        @$(".#{@controlSummaryClass}").html @getControlSummary()
        if @model.get('search_succeeded')
          Backbone.trigger("#{@resourceName}SearchSuccess",
            @model.get('search_message'), @model.get('id'))
        else
          Backbone.trigger("#{@resourceName}SearchFail",
            @model.get('search_message'), @model.get('id'))
        @stopSpin 'button.search'
        @enableSearchButton()

    fetchPhonologyFail: (error) ->
      Backbone.trigger "#{@resourceName}SearchFail", error, @model.get('id')
      @stopSpin 'button.search'
      @enableSearchButton()

    poll: -> setTimeout((=> @fetch()), 500)


