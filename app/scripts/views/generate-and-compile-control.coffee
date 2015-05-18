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

    # Write the initial HTML to the page.
    html: ->
      context =
        buttonClass: 'generate-and-compile'
        buttonTitle: 'Click this button to request that this parser’s FST
          script be generated and compiled so that it can be used to parse.'
        buttonText: 'Generate & Compile'
        controlResultsClass: 'generate-and-compile-results'
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

    generateAndCompile: ->
      console.log "start: generate_attempt is #{@model.get('generate_attempt')}"
      console.log "start: compile_attempt is #{@model.get('compile_attempt')}"
      @model.generateAndCompile()

    generateAndCompileStart: ->
      @spin 'button.generate-and-compile', '50%', '135%'
      @disableGenerateAndCompileButton()

    generateAndCompileEnd: ->
      @stopSpin 'button.generate-and-compile'
      @enableGenerateAndCompileButton()

    generateAndCompileFail: (error) ->
      Backbone.trigger 'morphologicalParserGenerateAndCompileFail', error,
        @model.get('id')

    # TODO: this isn't really a success. Now we must poll GET
    # /morphologicalparsers/id until compile attempt changes.
    generateAndCompileSuccess: ->
      console.log "success: generate_attempt is #{@model.get('generate_attempt')}"
      console.log "success: compile_attempt is #{@model.get('compile_attempt')}"
      Backbone.trigger 'morphologicalParserGenerateAndCompileSuccess',
        @model.get('id')

    disableGenerateAndCompileButton: ->
      @$('button.generate-and-compile').button 'disable'

    enableGenerateAndCompileButton: ->
      @$('button.generate-and-compile').button 'enable'

