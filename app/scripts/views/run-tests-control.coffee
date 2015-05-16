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

    actionResultsClass: 'run-tests-results'
    actionSummaryClass: 'run-tests-summary'

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
        actionResultsClass: @actionResultsClass
        actionSummaryClass: @actionSummaryClass

      @$el.html @template(context)

    render: ->
      @html()
      @guify()
      @listenToEvents()
      @$(".#{@actionResultsClass}").hide()
      @

    guify: ->
      @buttonify()
      @tooltipify()
      @$(".#{@actionResultsClass}")
       .css 'border-color': @constructor.jQueryUIColors().defBo

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

    runTestsSuccess: (testResults) ->
      Backbone.trigger "#{@resourceName}RunTestsSuccess", @model.get('id')
      @displayRunTestsResultsInTable testResults

    displayRunTestsResultsInTable: (testResults) ->
      testsArray = []
      passedCount = 0
      for uf, rObj of testResults
        tmp = [
          uf
          rObj.expected.join(', ')
          rObj.actual.join(', ')
        ]
        if (x for x in rObj.expected when x in rObj.actual).length
          passedCount += 1
          tmp.push "<i class='boolean-icon true fa fa-check'>"
          testsArray.push tmp
        else
          tmp.push "<i class='boolean-icon false fa fa-times'>"
          testsArray.unshift tmp

      table = ['<table class="io-results-table"><tr>
        <th>input</th>
        <th>expected output</th>
        <th>actual output</th>
        <th>passed/failed</th>
        </tr>']

      for array, index in testsArray
        [input, expected, actual, passedFailed] = array
        if (index % 2 is 0) then class_ = " class='ui-state-highlight'" else class_ = ''
        table.push "<tr #{class_}>
          <td>#{input}</td>
          <td>#{expected}</td>
          <td>#{actual}</td>
          <td>#{passedFailed}</td>
          </tr>"
      table.push "</table>"

      percentPassed =
        Math.round((passedCount / testsArray.length) * 10000) / 100
      msg = "#{percentPassed}% accurate: #{passedCount}/#{testsArray.length}
        tests passed."
      @$(".#{@actionSummaryClass}")
        .hide()
        .html msg
        .slideDown()

      @$(".#{@actionResultsClass}")
        .hide()
        .html table.join('')
        .slideDown()

    disableRunTestsButton: ->
      @$('button.run-tests').button 'disable'

    enableRunTestsButton: ->
      @$('button.run-tests').button 'enable'


