define [
  './base'
  './../utils/globals'
  './../templates/button-control'
  'autosize'
], (BaseView, globals, buttonControlTemplate) ->

  # Generate Control View
  # ---------------------
  #
  # View for a control for requesting that a language model be generated (i.e.,
  # estimated).

  class GenerateControlView extends BaseView

    modelClassName: 'LanguageModelModel'

    template: buttonControlTemplate
    className: 'generate-control-view control-view dative-widget-center'

    initialize: (options) ->
      @resourceName = options?.resourceName or 'languageModel'
      @activeServerType = @getActiveServerType()
      @listenToEvents()

    events:
      'click button.generate':         'generatePreflight'

    listenToEvents: ->
      super
      @listenTo @model, "generateStart", @generateStart
      @listenTo @model, "generateEnd", @generateEnd
      @listenTo @model, "generateFail", @generateFail
      @listenTo @model, "generateSuccess", @generateSuccess
      @listenTo @model, "trueGenerateFail",
        @trueGenerateFail
      @listenTo @model, "trueGenerateSuccess",
        @trueGenerateSuccess
      @listenTo @model, 'tooManyTasks', @enable
      @listenTo Backbone, 'change:longRunningTasks', @longRunningTasksChanged

    buttonClass: 'generate'
    controlSummaryClass: 'generate-summary'
    controlResultsClass: 'generate-results'
    controlResults: ''

    getControlSummary: ->
      switch @model.get('generate_succeeded')
        when true
          @controlSummary = "<i class='fa fa-check boolean-icon true'></i>
            Generate succeeded: #{@model.get('generate_message')}"
        when false
          @controlSummary = "<i class='fa fa-check boolean-icon false'></i>
            Generate failed: #{@model.get('generate_message')}"
        when null
          @controlSummary = "Nobody has yet attempted to generate this
            #{@resourceName}"

    # Write the initial HTML to the page.
    html: ->
      context =
        buttonClass: @buttonClass
        buttonTitle: "Click this button to request that this
          #{@utils.camel2regular @resourceName}’s FST script be generated and
          compiled so that it can be used."
        buttonText: 'Generate'
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
    # Generate
    ############################################################################

    # Before we initiate a `generate_and_compile` request, we must first check
    # with the TasksDialogView to see whether we have permission to do so,
    # i.e., whether we have too many in-progress requests pending.
    generatePreflight: ->
      @listenToOnce @model, 'preflightResponse', @preflightResponse
      Backbone.trigger 'longRunningTaskPreflight', @model, @model.get('UUID')

    # If the tasks manager (`TasksDialogView`) returns `goodToGo === false`
    # here, we do not allow the long-running task to be initiated.
    preflightResponse: (goodToGo, errorMsg='') ->
      if goodToGo
        @generate()
      else
        @enable()
        if errorMsg is 'taskAlreadyPending'
          Backbone.trigger 'taskAlreadyPending', 'generate',
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
        @disableGenerateButton()
        if statusMsg is 'taskAlreadyPending'
          @indicateGenerateInProgress()

    # The `TasksDialogView` has broadcast that the long-running tasks array has
    # changed. This may have consequences for this view; so we handle them
    # here.
    longRunningTasksChanged: (longRunningTasks, longRunningTasksMax) ->
      if longRunningTasks.length >= longRunningTasksMax
        @disableGenerateButton()
      else if @model.get('UUID') in (t.resourceId for t in longRunningTasks)
        @indicateGenerateInProgress()
      else
        @enable()

    generate: -> @model.generate()

    generateStart: ->
      @disableGenerateButton()
      Backbone.trigger 'generateStart', @model
      @indicateGenerateInProgress()

    indicateGenerateInProgress: ->
      @$(".#{@controlSummaryClass}").html ''
      @spin "button.#{@buttonClass}", '50%', '135%'

    generateEnd: ->

    generateFail: (error) ->
      Backbone.trigger "#{@resourceName}GenerateFail", error,
        @model.get('id')

    # This is called when we have made a successful `generate`
    # request. `trueGenerateSuccess` is called when the
    # `TasksDialogView` tells us (after polling) that the `generate_attempt`
    # value of our resource has changed and the generate request succeeded.
    generateSuccess: ->
      # The TasksDialogView is the controller for these long-running tasks. We
      # request that the task/request be initiated by triggering a
      # Backbone-wide event that the tasks dialog view listens for.
      params =
        resourceId: @model.get 'UUID'
        resourceName: @resourceName
        resourceModel: @model
        taskName: 'generate'
        taskStartTimestamp: new Date().getTime()
        taskEndTimestamp: null
        taskAttemptAttribute: 'generate_attempt'
        taskSuccessAttribute: 'generate_succeeded'
        taskMessageAttribute: 'generate_message'
        modelClassName: @modelClassName
      Backbone.trigger 'longRunningTask', params

    disableGenerateButton: ->
      @$("button.#{@buttonClass}").button 'disable'

    enableGenerateButton: ->
      @$("button.#{@buttonClass}").button 'enable'

    enable: ->
      @stopSpin "button.#{@buttonClass}"
      @enableGenerateButton()

    trueGenerateSuccess: ->
      @$(".#{@controlSummaryClass}").html @getControlSummary()
      @enable()

    trueGenerateFail: (error) ->
      @enable()

