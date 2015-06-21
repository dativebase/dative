define [
  './base'
  './../utils/globals'
  './../templates/button-control'
  'autosize'
], (BaseView, globals, buttonControlTemplate) ->

  # Generate and Compile Control View
  # ---------------------------------
  #
  # View for a control for requesting that a morphological parser or morphology
  # generate its FST script and then compile it.

  class GenerateAndCompileControlView extends BaseView

    modelClassName: 'MorphologyModel'

    template: buttonControlTemplate
    className: 'generate-and-compile-control-view control-view
      dative-widget-center'

    initialize: (options) ->
      @resourceName = options?.resourceName or 'morphologicalParser'
      @activeServerType = @getActiveServerType()
      @listenToEvents()

    events:
      'click button.generate-and-compile':         'generateAndCompilePreflight'

    listenToEvents: ->
      super
      @listenTo @model, "generateAndCompileStart", @generateAndCompileStart
      @listenTo @model, "generateAndCompileEnd", @generateAndCompileEnd
      @listenTo @model, "generateAndCompileFail", @generateAndCompileFail
      @listenTo @model, "generateAndCompileSuccess", @generateAndCompileSuccess
      @listenTo @model, "trueGenerateAndCompileFail",
        @trueGenerateAndCompileFail
      @listenTo @model, "trueGenerateAndCompileSuccess",
        @trueGenerateAndCompileSuccess
      @listenTo @model, 'tooManyTasks', @enable
      @listenTo Backbone, 'change:longRunningTasks', @longRunningTasksChanged

    buttonClass: 'generate-and-compile'
    controlSummaryClass: 'generate-and-compile-summary'
    controlResultsClass: 'generate-and-compile-results'
    controlResults: ''

    getControlSummary: ->
      switch @model.get('compile_succeeded')
        when true
          @controlSummary = "<i class='fa fa-check boolean-icon true'></i>
            Compile succeeded: #{@model.get('compile_message')}"
        when false
          @controlSummary = "<i class='fa fa-check boolean-icon false'></i>
            Compile failed: #{@model.get('compile_message')}"
        when null
          @controlSummary = "Nobody has yet attempted to compile this
            #{@resourceName}"

    # Write the initial HTML to the page.
    html: ->
      context =
        buttonClass: @buttonClass
        buttonTitle: "Click this button to request that this
          #{@utils.camel2regular @resourceName}’s FST script be generated and
          compiled so that it can be used."
        buttonText: 'Generate & Compile'
        controlResultsClass: @controlResultsClass
        controlSummaryClass: @controlSummaryClass
        controlResults: @controlResults
        controlSummary: @getControlSummary()
      @$el.html @template(context)

    render: ->
      @html()
      @guify()
      @listenToEvents()
      @listenToOnce @model, 'preflightResponse', @longRunningTaskAvailability
      Backbone.trigger 'longRunningTaskPreflight', @model, @model.get('UUID')
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
    # Generate & Compile
    ############################################################################

    # Before we initiate a `generate_and_compile` request, we must first check
    # with the TasksDialogView to see whether we have permission to do so,
    # i.e., whether we have too many in-progress requests pending.
    generateAndCompilePreflight: ->
      @listenToOnce @model, 'preflightResponse', @preflightResponse
      Backbone.trigger 'longRunningTaskPreflight', @model, @model.get('UUID')

    # If the tasks manager (`TasksDialogView`) returns `goodToGo === false`
    # here, we do not allow the long-running task to be initiated.
    preflightResponse: (goodToGo, errorMsg='') ->
      if goodToGo
        @generateAndCompile()
      else
        @enable()
        if errorMsg is 'taskAlreadyPending'
          Backbone.trigger 'taskAlreadyPending', 'generate and compile',
            @resourceName, @model
        else
          Backbone.trigger 'tooManyTasks'

    # This is called when we hear back from `TasksDialogView` regarding whether
    # we can even issue new long-running tasks. This is called on `render`.
    longRunningTaskAvailability: (goodToGo, statusMsg='') ->
      if goodToGo
        @enable()
        @$(".#{@controlSummaryClass}").html @getControlSummary()
      else
        @disableGenerateAndCompileButton()
        if statusMsg is 'taskAlreadyPending'
          @indicateGenerateAndCompileInProgress()

    # The `TasksDialogView` has broadcast that the long-running tasks array has
    # changed. This may have consequences for this view; so we handle them
    # here.
    longRunningTasksChanged: (longRunningTasks, longRunningTasksMax) ->
      if longRunningTasks.length >= longRunningTasksMax
        @disableGenerateAndCompileButton()
      else if @model.get('UUID') in (t.resourceId for t in longRunningTasks)
        @indicateGenerateAndCompileInProgress()
      else
        @enable()

    generateAndCompile: -> @model.generateAndCompile()

    generateAndCompileStart: ->
      @disableGenerateAndCompileButton()
      Backbone.trigger 'generateAndCompileStart', @model
      @indicateGenerateAndCompileInProgress()

    indicateGenerateAndCompileInProgress: ->
      @$(".#{@controlSummaryClass}").html ''
      @spin "button.#{@buttonClass}", '50%', '135%'

    generateAndCompileEnd: ->

    generateAndCompileFail: (error) ->
      Backbone.trigger "#{@resourceName}GenerateAndCompileFail", error,
        @model.get('id')

    # This is called when we have made a successful `generate_and_compile`
    # request. `trueGenerateAndCompileSuccess` is called when the
    # `TasksDialogView` tells us (after polling) that the `compile_attempt`
    # value of our resource has changed and the (generate and) compile request
    # succeeded.
    generateAndCompileSuccess: ->
      # The TasksDialogView is the controller for these long-running tasks. We
      # request that the task/request be initiated by triggering a
      # Backbone-wide event that the tasks dialog view listens for.
      params =
        resourceId: @model.get 'UUID'
        resourceName: @resourceName
        resourceModel: @model
        taskName: 'generateAndCompile'
        taskStartTimestamp: new Date().getTime()
        taskEndTimestamp: null
        taskAttemptAttribute: 'compile_attempt'
        modelClassName: @modelClassName
      Backbone.trigger 'longRunningTask', params

    disableGenerateAndCompileButton: ->
      @$("button.#{@buttonClass}").button 'disable'

    enableGenerateAndCompileButton: ->
      @$("button.#{@buttonClass}").button 'enable'

    enable: ->
      @stopSpin "button.#{@buttonClass}"
      @enableGenerateAndCompileButton()

    trueGenerateAndCompileSuccess: ->
      @$(".#{@controlSummaryClass}").html @getControlSummary()
      @enable()

    trueGenerateAndCompileFail: (error) ->
      @enable()

