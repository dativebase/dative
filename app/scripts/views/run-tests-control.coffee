define [
  './base'
  './../utils/globals'
  './../templates/button-control'
], (BaseView, globals, buttonControlTemplate) ->

  # Run Tests Control View
  # ----------------------
  #
  # View for a control for requesting that a phonology resource run the tests
  # defined in its script.

  class RunTestsControlView extends BaseView

    template: buttonControlTemplate
    className: 'run-tests-control-view control-view dative-widget-center'

    initialize: (options) ->
      @activeServerType = @getActiveServerType()
      @listenToEvents()
      @resourceName = options.resourceName or 'phonology'

    events:
      'click button.run-tests':         'runTests'

    listenToEvents: ->
      super
      @listenTo @model, "runTestsStart", @runTestsStart
      @listenTo @model, "runTestsEnd", @runTestsEnd
      @listenTo @model, "runTestsFail", @runTestsFail
      @listenTo @model, "runTestsSuccess", @runTestsSuccess

    # Write the initial HTML to the page.
    html: ->
      context =
        buttonClass: 'run-tests'
        buttonTitle: "Clicking this button will cause any tests defined
          in this phonology’s FST script to be performed and the results to be
          displayed."
        buttonText: 'Run Tests'
        actionResultsClass: 'run-tests-results'
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
    # Run Tests
    ############################################################################

    runTests: ->
      @model.runTests()

    runTestsStart: ->
      @spin 'button.run-tests', '50%', '135%'
      @disableRunTestsButton()

    runTestsEnd: ->
      @stopSpin 'button.run-tests'
      @enableRunTestsButton()

    runTestsFail: (error) ->
      Backbone.trigger "#{@resourceName}RunTestsFail", error, @model.get('id')

    runTestsSuccess: ->
      Backbone.trigger "#{@resourceName}RunTestsSuccess", @model.get('id')

    disableRunTestsButton: ->
      @$('button.run-tests').button 'disable'

    enableRunTestsButton: ->
      @$('button.run-tests').button 'enable'


