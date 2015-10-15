define [
  './base'
  './../utils/globals'
  './../templates/button-control'
], (BaseView, globals, buttonControlTemplate) ->

  # Display Collection Forms Control View
  # -------------------------------------
  #
  # View for a control that is a button that, when clicked, causes the
  # references to forms in the HTML value of a collection (already converted to
  # <div>s with data-id attributes) into FormView representations.

  class DisplayCollectionControlView extends BaseView

    template: buttonControlTemplate
    className: 'display-collection-forms-control-view control-view
      dative-widget-center'

    initialize: (options) ->
      @activeServerType = @getActiveServerType()
      @listenToEvents()

    events:
      'click button.display-collection-forms': 'fetchCollectionForms'

    listenToEvents: ->
      super
      @listenTo @model, "fetchCollectionStart", @fetchStart
      @listenTo @model, "fetchCollectionEnd", @fetchEnd
      @listenTo @model, "fetchCollectionFail", @fetchFail
      @listenTo @model, "fetchCollectionSuccess", @fetchSuccess

    controlSummaryClass: 'display-collection-forms-summary'
    controlResultsClass: 'display-collection-forms-results'
    controlResults: ''
    getControlSummary: -> ''

    buttonClass: 'display-collection-forms'

    html: ->
      context =
        buttonClass: @buttonClass
        buttonTitle: "Click this button to transform the references to forms in
          the “html” value into standard Dative-style form displays."
        buttonText: 'Display referenced forms'
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
    # Fetch
    ############################################################################

    # The OLD API gives us the forms of the collection (in
    # `{forms: [{...}, ...], ...}`) when we make a GET request to
    # /oldcollections/<collection_id>
    fetchCollectionForms: ->
      @model.fetchResource @model.id

    fetchStart: ->
      @$(".#{@controlSummaryClass}").html ''
      @spin "button.#{@buttonClass}", '50%', '135%'
      @disableDisplayButton()

    fetchEnd: ->
      @stopSpin "button.#{@buttonClass}"
      @enableDisplayButton()

    fetchFail: (error) ->
      Backbone.trigger "collectionFetchFormsFail", error, @model.get('id')

    fetchSuccess: (responseJSON) ->
      @$(".#{@controlSummaryClass}").html("The forms referenced in this
        collection have been fetched.")
      # @model.set 'forms', responseJSON.forms
      Backbone.trigger "collectionFetchFormsSuccess", @model.get('id')
      @model.trigger "formsFetchedForDisplay", responseJSON.forms

    disableDisplayButton: ->
      @$("button.#{@buttonClass}").button 'disable'

    enableDisplayButton: ->
      @$("button.#{@buttonClass}").button 'enable'

