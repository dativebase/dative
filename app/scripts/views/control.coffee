define [
  './base'
  './../utils/globals'
  './../templates/controls'
  'autosize'
], (BaseView, globals, controlTemplate) ->

  # Control View
  # ------------------
  #
  # View for a control, i.e., a set of buttons, inputs and display elements
  # that allow users to perform actions on specific resources. An example would
  # be a control that allows users to request a parse from a parser resource or
  # to request the compilation of a parser.

  class ControlView extends BaseView

    template: controlTemplate
    className: 'control-view dative-widget-center'

    initialize: (options) ->
      @activeServerType = @getActiveServerType()
      @listenToEvents()

    events:
      'click button.hide-controls-widget': 'hideSelf'
      'click button.generate-and-compile':         'generateAndCompile'
      'click button.parse':                        'parse'
      'keydown':                                   'keydown'
      'input textarea[name=parse]':                'parseInputState'
      # 'click button.applydown':                    'applydown'
      # 'click button.applyup':                      'applyup'
      # 'click button.export':                       'export'
      # 'click button.generate':                     'generate'
      # 'click button.history':                      'history'
      # 'click button.serve-compiled':               'serveCompiled'

    # The resource super-view will handle this hiding.
    hideSelf: -> @trigger "controlsView:hide"

    keydown: (event) ->
      event.stopPropagation()
      switch event.which
        when 13 # CTRL+RETURN clicks the "Parse" button
          if event.ctrlKey
            event.preventDefault()
            @$('button.parse').first().click()
        when 27 # ESC closes the controls widget
          @stopEvent event
          @hideSelf()

    listenToEvents: ->
      super

      @listenTo @model, "parseStart", @parseStart
      @listenTo @model, "parseEnd", @parseEnd
      @listenTo @model, "parseFail", @parseFail
      @listenTo @model, "parseSuccess", @parseSuccess

      @listenTo @model, "generateAndCompileStart", @generateAndCompileStart
      @listenTo @model, "generateAndCompileEnd", @generateAndCompileEnd
      @listenTo @model, "generateAndCompileFail", @generateAndCompileFail
      @listenTo @model, "generateAndCompileSuccess", @generateAndCompileSuccess

    # Write the initial HTML to the page.
    html: ->
      context =
        headerTitle: 'Controls'
        activeServerType: @getActiveServerType()
      @$el.html @template(context)

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

    render: ->
      @html()
      @guify()
      @listenToEvents()
      @

    guify: ->
      @fixRoundedBorders() # defined in BaseView
      @buttonify()
      @tooltipify()
      @$el.css 'border-color': @constructor.jQueryUIColors().defBo
      @bordercolorify()
      @autosize()
      @disableParseButton()

    tooltipify: ->
      @$('.dative-tooltip').not('button.parse')
        .tooltip position: @tooltipPositionLeft('-20')
      @$('.dative-tooltip.parse')
        .tooltip position: @tooltipPositionRight('+20')

    # Make the border colors match the jQueryUI theme.
    bordercolorify: ->
      @$('textarea, input')
        .css "border-color", @constructor.jQueryUIColors().defBo

    autosize: -> @$('textarea').autosize append: false

    buttonify: -> @$('button').button()


    ############################################################################
    # Parse
    ############################################################################

    parseInputState: ->
      input = @$('textarea[name=parse]').val()
      parseButtonDisabled = @$('button.parse').button 'option', 'disabled'
      if input
        if parseButtonDisabled then @enableParseButton()
      else
        if not parseButtonDisabled then @disableParseButton()

    parse: ->
      input = @$('textarea[name=parse]').val()
      @model.parse input

    parseStart: ->
      @spin 'button.parse', '50%', '135%'
      @disableParseButton()

    parseEnd: ->
      @stopSpin 'button.parse'
      @enableParseButton()

    parseFail: (error) ->
      Backbone.trigger 'morphologicalParseFail', error, @model.get('id')

    parseSuccess: ->
      Backbone.trigger 'morphologicalParseSuccess', @model.get('id')

    disableParseButton: -> @$('button.parse').button 'disable'

    enableParseButton: -> @$('button.parse').button 'enable'

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



