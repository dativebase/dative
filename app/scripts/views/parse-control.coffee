define [
  './base'
  './../utils/globals'
  './../templates/textarea-button-control'
  'autosize'
], (BaseView, globals, textareaButtonControlTemplate) ->

  # Parse Control View
  # ------------------
  #
  # View for a control for requesting a parse from a morphological parser.

  class ParseControlView extends BaseView

    template: textareaButtonControlTemplate
    className: 'parse-control-view control-view dative-widget-center'

    initialize: (options) ->
      @activeServerType = @getActiveServerType()
      @listenToEvents()

    events:
      'click button.parse':                        'parse'
      'keydown textarea[name=parse]':              'inputKeydown'
      'input textarea[name=parse]':                'parseInputState'

    inputKeydown: (event) ->
      switch event.which
        when 13 # CTRL+RETURN clicks the "Parse" button
          event.stopPropagation()
          if event.ctrlKey
            event.preventDefault()
            @$('button.parse').first().click()
        when 27
          console.log 'ESC'
        else
          event.stopPropagation()

    listenToEvents: ->
      super
      @listenTo @model, "parseStart", @parseStart
      @listenTo @model, "parseEnd", @parseEnd
      @listenTo @model, "parseFail", @parseFail
      @listenTo @model, "parseSuccess", @parseSuccess

    # Write the initial HTML to the page.
    html: ->
      context =
        textareaName: 'parse'
        textareaTitle: 'Enter one or more words here and click the “Parse”
          button in order to parse those words using this parser.'
        buttonClass: 'parse'
        buttonTitle: 'Enter one or more words in the input on the left and
          click here in order to parse those words using this parser.'
        buttonText: 'Parse'
        resultsContainerClass: 'parse-results'
      @$el.html @template(context)

    render: ->
      @html()
      @guify()
      @disableParseButton()
      @listenToEvents()
      @

    guify: ->
      @buttonify()
      @tooltipify()
      @bordercolorify()
      @autosize()

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

    parseSuccess: (parseResults) ->
      Backbone.trigger 'morphologicalParseSuccess', @model.get('id')
      @displayParseResultsInTable parseResults

    parseHTML: (parse) ->
      # nit|1|agra-ihpiyi|dance|vai
      if parse
        shapes = []
        glosses = []
        cats = []
        # TODO: this should be based on delimiters in app settings ...
        delims = ['-', '=']
        splitter = new RegExp "(#{delims.join '|'})"
        for morpheme in parse.split splitter
          if morpheme in delims
            shapes.push morpheme
            glosses.push morpheme
            cats.push morpheme
          else
            [shape, gloss, cat] = morpheme.split '\u2980'
            shapes.push shape
            glosses.push gloss
            cats.push cat
        "<div>#{shapes.join ''}</div>\
          <div>#{glosses.join ''}</div>\
          <div>#{cats.join ''}</div"
      else
        'no parse'

    displayParseResultsInTable: (parseResults) ->
      table = ['<table class="io-results-table">
        <tr><th>words</th><th>parses</th></tr>']
      oddEven = 0
      parses = ([w, @parseHTML(p)] for w, p of parseResults)
      for [word, parse] in parses
        if oddEven is 0
          oddEven = 1
          table.push "<tr class='even'><td>#{word}</td>
            <td>#{parse}</td></tr>"
        else
          oddEven = 0
          table.push "<tr><td>#{word}</td><td>#{parse}</td></tr>"
      table.push "</table>"
      @$('.parse-results')
        .hide()
        .html table.join('')
        .slideDown()

    disableParseButton: -> @$('button.parse').button 'disable'

    enableParseButton: -> @$('button.parse').button 'enable'

