define [
  './base'
  './../utils/globals'
  './../templates/button-control'
  'autosize'
], (BaseView, globals, buttonControlTemplate) ->

  # Generate and Compile Control View
  # ---------------------------------
  #
  # View for a control for requesting that a morphological parser generate its
  # FST script and then compile it.

  class GenerateAndCompileControlView extends BaseView

    template: buttonControlTemplate
    className: 'generate-and-compile-control-view control-view
      dative-widget-center'

    initialize: (options) ->
      @resourceName = options?.resourceName or 'morphologicalParser'
      @activeServerType = @getActiveServerType()
      @listenToEvents()

    events:
      'click button.generate-and-compile':         'generateAndCompile'

    listenToEvents: ->
      super
      @listenTo @model, "generateAndCompileStart", @generateAndCompileStart
      @listenTo @model, "generateAndCompileEnd", @generateAndCompileEnd
      @listenTo @model, "generateAndCompileFail", @generateAndCompileFail
      @listenTo @model, "generateAndCompileSuccess", @generateAndCompileSuccess
      @listenTo @model, "fetch#{@utils.capitalize @resourceName}Success",
        @fetchResourceSuccess
      @listenTo @model, "fetch#{@utils.capitalize @resourceName}Fail",
        @fetchResourceFail

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

    generateAndCompile: -> @model.generateAndCompile()

    generateAndCompileStart: ->
      Backbone.trigger 'generateAndCompileStart', @model
      @$(".#{@controlSummaryClass}").html ''
      @spin "button.#{@buttonClass}", '50%', '135%'
      @disableGenerateAndCompileButton()

    generateAndCompileEnd: ->

    generateAndCompileFail: (error) ->
      Backbone.trigger "#{@resourceName}GenerateAndCompileFail", error,
        @model.get('id')

    generateAndCompileSuccess: ->
      @compileAttempt = @model.get('compile_attempt')
      @poll()

    disableGenerateAndCompileButton: ->
      @$("button.#{@buttonClass}").button 'disable'

    enableGenerateAndCompileButton: ->
      @$("button.#{@buttonClass}").button 'enable'

    fetch: ->
      @model.fetchResource @model.get('id')

    fetchResourceSuccess: (resourceObject) ->
      if resourceObject.compile_attempt is @compileAttempt
        @poll()
      else
        @model.set
          compile_succeeded: resourceObject.compile_succeeded
          compile_attempt: resourceObject.compile_attempt
          compile_message: resourceObject.compile_message
          datetime_modified: resourceObject.datetime_modified
          modifier: resourceObject.modifier
        @$(".#{@controlSummaryClass}").html @getControlSummary()
        if @model.get('compile_succeeded')
          Backbone.trigger("#{@resourceName}CompileSuccess",
            @model.get('compile_message'), @model.get('id'))
        else
          Backbone.trigger("#{@resourceName}CompileFail",
            @model.get('compile_message'), @model.get('id'))
        @stopSpin "button.#{@buttonClass}"
        @enableGenerateAndCompileButton()

    fetchResourceFail: (error) ->
      Backbone.trigger "#{@resourceName}GenerateAndCompileFail", error, @model.get('id')
      @stopSpin "button.#{@buttonClass}"
      @enableGenerateAndCompileButton()

    poll: -> setTimeout((=> @fetch()), 500)

