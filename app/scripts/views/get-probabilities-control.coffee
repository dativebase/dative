define [
  './base'
  './../utils/globals'
  './../templates/get-probabilities-control'
  'autosize'
], (BaseView, globals, getProbabilitiesControlTemplate) ->

  # Get Probabilities Control View
  # ------------------------------
  #
  # View for a control for making a `getprobabilities` request against an
  # LM.
  #
  # This is a PUT requests against an OLD web service's
  # /morphemelanguagemodels/{id}/get_probabilities URL. The request body should
  # contain a JSON object of the form::
  #
  #     morpheme_sequences: [Array]
  #
  # where `Array` is an array of strings, each of which is a space-delimited
  # morpheme in form|gloss|category format wherer "|" is actually the specified
  # rare delimiter, which, by default is U+2980.

  class GetProbabilitiesControlView extends BaseView

    # Change these attributes when subclassing this.
    buttonText: 'Get Probabilities'
    resourceName: 'languageModel'
    textareaTitle: ->
      "Enter some morphologically analyzed words here and we’ll tell you
        their probabilities according to this language model."
    buttonTitle: ->
      "Enter some morphologically analyzed words in the input on the left and
        click here and we’ll tell you their probabilities according to this
        language model."

    template: getProbabilitiesControlTemplate
    className: ->
      "get-probabilities-control-view control-view dative-widget-center"

    initialize: (options) ->
      @activeServerType = @getActiveServerType()
      @listenToEvents()
      @events["click button.get-probabilities"] = 'getProbabilities'
      @events["keydown textarea[name=get-probabilities]"] = 'inputKeydown'
      @events["input textarea[name=get-probabilities]"] =
        'getProbabilitiesInputState'
      @events['click button.rare-delimiter-insert'] = 'insertRareDelimiterAtCursorPosition'

    events: {}

    # Insert the rare delimiter at the cursor position (or replace the selected
    # text with it).
    insertRareDelimiterAtCursorPosition: (maintainSelection=true) ->
      delimiter = @model.get 'rare_delimiter'
      $input = @$('textarea[name=get-probabilities]').first()
      inputDOM = $input.get 0
      currentVal = $input.val()
      cursorStart = inputDOM.selectionStart
      cursorEnd = inputDOM.selectionEnd
      newVal =
        "#{currentVal[...cursorStart]}#{delimiter}#{currentVal[cursorEnd...]}"
      $input.val newVal
      # For some reason, if we manually set the selection positions when this
      # method call is triggered by a keyboard event, then this doesn't work.
      if maintainSelection
        inputDOM.selectionStart = cursorStart
        inputDOM.selectionEnd = (cursorStart + delimiter.length)
      inputDOM.focus()

    inputKeydown: (event) ->
      switch event.which
        when 13 # CTRL+RETURN clicks the "Get Probabilities" button
          event.stopPropagation()
          if event.ctrlKey
            event.preventDefault()
            @$("button.get-probabilities").first().click()
        when 27
          false
        when 68 # Ctrl+D inserts rare delimiter
          if event.ctrlKey then @insertRareDelimiterAtCursorPosition false
          event.stopPropagation()
        else
          event.stopPropagation()

    listenToEvents: ->
      super
      @listenTo @model, "getProbabilitiesStart", @getProbabilitiesStart
      @listenTo @model, "getProbabilitiesEnd", @getProbabilitiesEnd
      @listenTo @model, "getProbabilitiesFail", @getProbabilitiesFail
      @listenTo @model, "getProbabilitiesSuccess", @getProbabilitiesSuccess
      @listenTo @model, "change:generate_succeeded", @generateSucceededChanged

    generateSucceededChanged: ->
      if @model.get('generate_succeeded') is false
        @disableGetProbabilitiesButton()
        @disableGetProbabilitiesInput()
      else
        @enableGetProbabilitiesButton()
        @enableGetProbabilitiesInput()

    getProbabilitiesInputAbility: ->
      if @model.get('generate_succeeded') is false
        @disableGetProbabilitiesInput()
      else
        @enableGetProbabilitiesInput()

    # Write the initial HTML to the page.
    html: ->
      context =
        textareaName: "get-probabilities"
        textareaTitle: @textareaTitle()
        buttonClass: "get-probabilities"
        buttonTitle: @buttonTitle()
        buttonText: @buttonText
        resultsContainerClass: "get-probabilities-results"
        rareDelimiter: @model.get 'rare_delimiter'
      @$el.html @template(context)

    render: ->
      @html()
      @guify()
      @disableGetProbabilitiesButton()
      @getProbabilitiesInputAbility()
      @listenToEvents()
      @

    guify: ->
      @buttonify()
      @tooltipify()
      @bordercolorify()
      @autosize()

    tooltipify: ->
      @$('.dative-tooltip').not("button.get-probabilities")
        .tooltip position: @tooltipPositionLeft('-20')
      @$(".dative-tooltip.get-probabilities")
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
    # Get Probabilities
    ############################################################################

    getProbabilitiesInputState: ->
      input = @$("textarea[name=get-probabilities]").val()
      getProbabilitiesButtonDisabled =
        @$("button.get-probabilities").button 'option', 'disabled'
      if input
        if getProbabilitiesButtonDisabled then @enableGetProbabilitiesButton()
      else
        if not getProbabilitiesButtonDisabled
          @disableGetProbabilitiesButton()

    getProbabilities: ->
      input = @$("textarea[name=get-probabilities]").val()
      words = (word.trim() for word in input.split('\n'))
      @model.getProbabilities(morpheme_sequences: words)

    getProbabilitiesStart: ->
      @spin "button.get-probabilities", '50%', '120%'
      @disableGetProbabilitiesButton()

    getProbabilitiesEnd: ->
      @stopSpin "button.get-probabilities"
      @enableGetProbabilitiesButton()

    getProbabilitiesFail: (error) ->
      Backbone.trigger 'languageModelGetProbabilitiesFail', error,
        @model.get('id')

    getProbabilitiesSuccess: (getProbabilitiesResults) ->
      Backbone.trigger 'languageModelGetProbabilitiesSuccess', @model.get('id')
      @displayGetProbabilitiesResultsInTable getProbabilitiesResults

    displayGetProbabilitiesResultsInTable: (getProbabilitiesResults) ->
      probabilities = ([Math.pow(10, prob), word] \
        for word, prob of getProbabilitiesResults).sort().reverse()
      table = ['<table class="io-results-table">
        <tr><th>words</th><th>probabilities</th></tr>']
      oddEven = 0
      for [prob, word] in probabilities
        if oddEven is 0
          oddEven = 1
          table.push "<tr class='even'><td>#{word}</td>
            <td>#{prob}</td></tr>"
        else
          oddEven = 0
          table.push "<tr><td>#{word}</td><td>#{prob}</td></tr>"
      table.push "</table>"
      @$(".get-probabilities-results")
        .hide()
        .html table.join('')
        .slideDown()

    disableGetProbabilitiesButton: -> @$("button.get-probabilities").button 'disable'
    enableGetProbabilitiesButton: -> @$("button.get-probabilities").button 'enable'

    disableGetProbabilitiesInput: ->
      @$("textarea[name=get-probabilities]").attr 'disabled', true

    enableGetProbabilitiesInput: ->
      @$("textarea[name=get-probabilities]").attr 'disabled', false



