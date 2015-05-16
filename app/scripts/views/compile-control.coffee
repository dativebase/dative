define [
  './base'
  './../utils/globals'
  './../templates/button-control'
], (BaseView, globals, buttonControlTemplate) ->

  # Compile Control View
  # --------------------
  #
  # View for a control for requesting that an FST-based resource attempt to
  # compile itself.

  class CompileControlView extends BaseView

    template: buttonControlTemplate
    className: 'compile-control-view control-view dative-widget-center'

    initialize: (options) ->
      @activeServerType = @getActiveServerType()
      @listenToEvents()
      @resourceName = options.resourceName or 'phonology'

    events:
      'click button.compile':         'compile'

    listenToEvents: ->
      super
      @listenTo @model, "compileStart", @compileStart
      @listenTo @model, "compileEnd", @compileEnd
      @listenTo @model, "compileFail", @compileFail
      @listenTo @model, "compileSuccess", @compileSuccess
      @listenTo @model, "fetchPhonologySuccess", @fetchPhonologySuccess
      @listenTo @model, "fetchPhonologyFail", @fetchPhonologyFail

    # Write the initial HTML to the page.
    html: ->
      context =
        buttonClass: 'compile'
        buttonTitle: "Click this button to request that this
          #{@resourceName}’s FST script be compiled so that it can be used to
          map underlying representations to surface ones or vice versa."
        buttonText: 'Compile'
        actionResultsClass: 'compile-results'
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
    # Compile
    ############################################################################

    compile: -> @model.compile()

    compileStart: ->
      @spin 'button.compile', '50%', '135%'
      @disableCompileButton()

    compileEnd: ->

    compileFail: (error) ->
      Backbone.trigger "#{@resourceName}CompileFail", error, @model.get('id')

    compileSuccess: ->
      @compileAttempt = @model.get('compile_attempt')
      @poll()

    disableCompileButton: ->
      @$('button.compile').button 'disable'

    enableCompileButton: ->
      @$('button.compile').button 'enable'

    fetch: -> @model.fetchResource @model.get('id')

    fetchPhonologySuccess: (phonologyObject) ->
      if phonologyObject.compile_attempt is @compileAttempt
        @poll()
      else
        @model.set
          compile_succeeded: phonologyObject.compile_succeeded
          compile_attempt: phonologyObject.compile_attempt
          compile_message: phonologyObject.compile_message
        if @model.get('compile_succeeded')
          Backbone.trigger("#{@resourceName}CompileSuccess",
            @model.get('compile_message'), @model.get('id'))
        else
          Backbone.trigger("#{@resourceName}CompileFail",
            @model.get('compile_message'), @model.get('id'))
        @stopSpin 'button.compile'
        @enableCompileButton()

    fetchPhonologyFail: (error) ->
      Backbone.trigger "#{@resourceName}CompileFail", error, @model.get('id')
      @stopSpin 'button.compile'
      @enableCompileButton()

    poll: -> setTimeout((=> @fetch()), 500)

