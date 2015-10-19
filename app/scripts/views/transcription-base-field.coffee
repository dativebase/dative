define [
  './field'
  './../models/morphological-parser'
  './../templates/field-suggestible'
  './../utils/globals'
], (FieldView, MorphologicalParserModel, suggestibleFieldTemplate, globals) ->

  # Transcription Base Field View
  # -----------------------------
  #
  # Transcription fields can be both suggesters and suggestion receivers. They
  # may:
  #
  # 1. receive suggestions from morpheme break fields (based on phonologies)
  # 2. give suggestions to morpheme break fields (using parsers)
  #
  # This field is to be inherited by field views for transcription-type
  # fields/attributes, i.e.,  'transcription', 'phonetic_transcription', and
  # 'narrow_phonetic_transcription'.
  #
  # The special-purpose logic in this class is for triggering suggestions and
  # reacting to suggestions that target these fields.

  class TranscriptionBaseFieldView extends FieldView

    events:
      'change':                'setToModel' # fires when multi-select changes
      'selectmenuchange':      'setToModel' # fires when a selectmenu changes
      'menuselect':            'setToModel' # fires when the tags multi-select changes (not working?...)
      'keydown .ms-container': 'multiselectKeydown'
      # New/different from `FieldView` super-class.
      'keydown input, .ui-selectmenu-button, .ms-container':
                               'controlEnterSubmit'
      'keydown textarea':      'myControlEnterSubmit'
      'input':                 'respondToInput' # fires when an input, textarea or date-picker changes
      'keydown div.suggestion':
                               'suggestionsKeyboardControl'
      'click .toggle-suggestions':
                               'toggleSuggestions'
      'click div.suggestion':  'suggestionClicked'
      'mouseover .suggestion': 'hoverStateSuggestionOn'
      'mouseout .suggestion':  'hoverStateSuggestionOff'
      'focusin .suggestion':   'hoverStateSuggestionOn'
      'focusout .suggestion':  'hoverStateSuggestionOff'

    template: suggestibleFieldTemplate

    initialize: (options) ->
      super options

      ##########################################################################
      # Suggestion RECEIVER attributes
      ##########################################################################

      # When set to `true` this means that the (suggestion) system is
      # responsible for the current value in our <textarea>. When set to
      # `false` (the default), this means that the user is responsible for this
      # value; this prevents the suggestions we receive from overwriting the
      # user-specified input.
      @systemSuggested = false

      # This array will hold suggestions (strings) for this transcription
      # field.
      @suggestedValues = []

      # This will hold any suggestion object that we may receive.
      @suggestionUnaltered = null

      # Indicates whether the suggestions are visible in the UI.
      @suggestionsVisible = false

      ##########################################################################
      # Suggestion ISSUER attributes
      ##########################################################################

      # For keeping track of the words seen as a user modifies the
      # transcription input field. This is an array of all of the unique words
      # that the user has typed into the transcription field.
      @wordsSeen = []

      # This array will hold strings that we've already requested parses for.
      @parseRequested = []

      # This cache object maps input words (from the user) to output parses
      # previously returned by the server.
      @parseCache = {}

      @parser = @getParser()

      @parseRequestPending = false

      # Return an array of field names that we may target, i.e., send
      # suggestions to.
      @targetFields = @getTargetFields()

    listenToEvents: ->
      super

      # Something is offering us a suggestion for what our transcription value
      # should be.
      @listenTo @model, "#{@attribute}:suggestion", @suggestionReceived

      # Something is telling us to hide our current suggestions. This happens
      # when a morpheme break field recognizes that its "to-X-transcription"
      # phonology has changed to `null`.
      @listenTo @model, "#{@attribute}:turnOffSuggestions", @turnOffSuggestions

      # The input view's <textarea> has resized itself, so we respond by resizing
      # our .suggestions <div>.
      @listenTo @model, 'textareaWidthResize', @resizeAndPositionSuggestionsDiv

      @listenToParser()
      @listenForParserTaskSetChange()

    render: ->
      @lastInput = new Date()
      @setIntervalId = setInterval (=> @requestParseCheck()), 500
      super
      @

    guify: ->
      super
      @guifyForSuggestions()

    onClose: -> clearInterval @setIntervalId

    # The user has entered something into the <textarea>.
    respondToInput: ->
      # The super-class would have called `setToModel` on an input event, so we
      # do that here too.
      @setToModel()

      # Remember the timestamp of the last input event; this info will be used
      # to decide when we should make requests to the server.
      @lastInput = new Date()

      # Update `@wordsSeen` so that it is an array of all of the words that we
      # have seen the user type into our field (with no duplicates).
      currentWords = @getCurrentWords()
      @wordsSeen = @utils.unique @wordsSeen.concat(currentWords)

      if @parser then @triggerSuggestion()
      @systemSuggested = false
      @alertIncongruity()


    ############################################################################
    # Suggestion RECEIVER logic
    ############################################################################

    guifyForSuggestions: ->
      @$('.suggestions')
        .css "border-color", @constructor.jQueryUIColors().defBo
      @$('button.toggle-suggestions')
        .button()
        .tooltip()
        .hide()
      setTimeout (=> @resizeAndPositionSuggestionsDiv()), 10

    hoverStateSuggestionOn: (event) ->
      @$(event.currentTarget).addClass 'ui-state-hover'

    hoverStateSuggestionOff: (event) ->
      @$(event.currentTarget).removeClass 'ui-state-hover'

    # <Ctrl+Enter> should still submit the form, but now <down arrow> should
    # open the suggestions <div>.
    # NOTE: I stopped stopping the event because stopping it means that you can
    # no longer move up and down within the textarea using the arrow keys.
    # However, this doesn't really fix things for the down arrow since in that
    # case the first suggestion becomes highlighted and you don't move to the
    # next line (or end of) the textarea anyways.
    myControlEnterSubmit: (event) ->
      switch event.which
        when 40
          # @stopEvent event
          @openSuggestionsAnimateCheck()
        when 38
          # @stopEvent event
          if @$('.suggestions').length > 0 then @closeSuggestionsAnimate()
      @controlEnterSubmit event

    # We have received a suggestion; respond accordingly. This means:
    # 1. potentially inserting the primary suggestion into our <textarea>
    # 2. populating our .suggestions <div> with (a subset of) the suggestions.
    # 3. alerting the user if their current value is not in the suggestions
    #    list.
    suggestionReceived: (suggestion) ->
      $input = @$("textarea[name=#{@attribute}]").first()
      currentValue = $input.val().trim()
      @suggestionUnaltered = suggestion
      @suggestedValues = @getSuggestedValues suggestion
      if (@systemSuggested or (not currentValue)) and
      @suggestedValues.length > 0
        @systemSuggested = true
        $input.val @suggestedValues[0]
        @setToModel()
      @addSuggestionsToSuggestionsDiv()

    turnOffSuggestions: ->
      @closeSuggestionsAnimate()
      @suggestionsVisible = false
      @toggleSuggestionsButtonState()
      @suggestedValues = []

    # Due to combinatoric explosion, we can get too many suggestions, so we
    # display this many at most.
    maxNoSuggestions: 20

    # Populate our .suggestions <div> with our first `@maxNoSuggestions`
    addSuggestionsToSuggestionsDiv: ->
      if @suggestedValues.length > 0
        @alertIncongruity()
        @showSuggestionsButtonCheck()
        @$('.suggestions').first().html @getSuggestedValuesHTML()
        # If nothing is currently focused, we take that to mean that the last
        # thing focused was a .suggestion <div> that we just destroyed; so we
        # focus the first new .suggestion <div>.
        if $(':focus').length is 0
          @$('.suggestions').first().find('.suggestion').first().focus()
      else
        @$('.suggestions').html ''
        @hideSuggestionsButtonCheck()

    # We set the width and position of the .suggestions <div> in accordance
    # with the with and position of the <textarea> that the suggestions are
    # for.
    # TODO: fix minor bug: right now the .suggestions <div> will be incorrectly
    # positioned when first revealed. It quickly fixes itself, but this could
    # be better.
    resizeAndPositionSuggestionsDiv: ->
      $textarea = @$("textarea[name=#{@attribute}]").first()
      $suggestionsDiv = @$('.suggestions').first()
      textareaWidth = $textarea.width()
      if textareaWidth
        if @attribute is 'transcription'
          newWidth = textareaWidth + 19.5
        else
          newWidth = textareaWidth + 19
        $suggestionsDiv.css 'width', "#{newWidth}px"
      if $suggestionsDiv.is ':visible'
        $suggestionsDiv.position
          my: 'left top'
          at: 'left bottom-5'
          of: $textarea
          collision: 'none'

    # Get the HTML for displaying our array of selections (truncated, if
    # needed).
    getSuggestedValuesHTML: ->
      result = []
      for suggestion in @suggestedValues[...@maxNoSuggestions]
        result.push "<div class='suggestion' tabindex='0'>#{suggestion}</div>"
      result.join ''

    removePunctuation: (value) ->
      value.replace(/['"“”‘’,.!?]/g, '')

    # Alert the user to the fact that their transcription-type value does not
    # match any of the values in the received suggestion. We perform this alert
    # by adding an Error class to the small "show suggestions" button, changing
    # the tooltip message, and giving it an "Error" appearance too.
    alertIncongruity: ->
      if @suggestedValues and @suggestedValues.length > 0
        value = @model.get @attribute
        if value in @suggestedValues or
        value.toLowerCase() in @suggestedValues or
        @removePunctuation(value.toLowerCase()) in @suggestedValues or
        @utils.singleSpace(@removePunctuation(value.toLowerCase())) in @suggestedValues
          @$('button.toggle-suggestions').first()
            .removeClass 'ui-state-error'
            .tooltip 'option', 'content', 'show suggested values for this field'
            .tooltip 'option', 'tooltipClass', ''
        else
          @$('button.toggle-suggestions').first()
            .addClass 'ui-state-error'
            .tooltip 'option', 'content', "Warning: the value in this field is
              not among the values suggested by
              #{@suggestionUnaltered.suggester} given the
              #{@utils.snake2regular @suggestionUnaltered.source} value; click
              here to show suggested values for this field"
            .tooltip 'option', 'tooltipClass', 'ui-state-error'

    # Respond to a 'click' event on a <div.selection> element: put its
    # suggestion text in our <textarea>.
    suggestionClicked: (event) ->
      suggestion = @$(event.currentTarget).text()
      $textarea = @$("textarea[name=#{@attribute}]").first()
      $textarea.val suggestion
      @setToModel()
      @suggestionsVisible = false
      @toggleSuggestionsButtonState()
      @$('.suggestions').first().slideUp
        complete: -> $textarea.focus()

    # (Animatedly) toggle the suggestions <div>.
    toggleSuggestions: ->
      $suggestionsDiv = @$('.suggestions').first()
      if $suggestionsDiv.is ':visible'
        @suggestionsVisible = false
        $suggestionsDiv.slideUp()
      else
        @suggestionsVisible = true
        $suggestionsDiv.slideDown
          complete: =>
            @resizeAndPositionSuggestionsDiv()
      @toggleSuggestionsButtonState()

    # Open the suggestions <div> (animatedly) and focus the first suggestion.
    openSuggestionsAnimateCheck: ->
      if @suggestedValues.length > 0
        @suggestionsVisible = true
        $suggestionsDiv = @$('.suggestions').first()
        if not $suggestionsDiv.is ':visible'
          $suggestionsDiv.slideDown
            complete: =>
              @resizeAndPositionSuggestionsDiv()
        $suggestionsDiv.find('.suggestion').first().focus()
      else
        @suggestionsVisible = false
      @toggleSuggestionsButtonState()

    # Close the suggestions <div> (animatedly) and focus our <textarea>.
    closeSuggestionsAnimate: ->
      @suggestionsVisible = false
      @toggleSuggestionsButtonState()
      @$('.suggestions').first().slideUp()
      @$("textarea[name=#{@attribute}]").first().focus()

    # The suggestions <div> has caught a keydown event:
    # - down arrow focuses next suggestion
    # - up arrow focuses previous suggestion (or closes <div> if at top)
    # - <Return> selects focused suggestion (puts it in <textarea>)
    # - <Esc> closes suggestions <div> and focuses textarea
    suggestionsKeyboardControl: (event) ->
      switch event.which
        when 40
          @stopEvent event
          $focused = @$(':focus')
          $next = $focused.next()
          if $next then $next.focus()
        when 38
          @stopEvent event
          $focused = @$(':focus')
          $prev = $focused.prev()
          if $prev.length > 0
            $prev.focus()
          else
            @closeSuggestionsAnimate()
        when 13
          @stopEvent event
          @$(event.currentTarget).click()
        when 27
          @stopEvent event
          @closeSuggestionsAnimate()

    # title='show suggested values for this <%= @label %> field'
    toggleSuggestionsButtonState: ->
      $button = @$ 'button.toggle-suggestions'
      if @suggestionsVisible
        $button.tooltip content: "hide suggested values for this
          #{@context.label} field"
      else
        $button.tooltip content: "show suggested values for this
          #{@context.label} field"

    # Show the "toggle suggestions" button if it's not yet visible.
    showSuggestionsButtonCheck: ->
      $button = @$('button.toggle-suggestions')
      if not $button.is(':visible') then $button.show()

    # Hide the "toggle suggestions" button (if it is visible).
    hideSuggestionsButtonCheck: ->
      $button = @$('button.toggle-suggestions')
      if $button.is(':visible') then $button.hide()

    # Given the suggestor's `suggestion` object, construct an array of
    # suggestions (strings) that we can use. Implicitly, the first element in
    # this array will be interpreted as the primary suggestion.
    # Param `suggestion.suggestion` is an object that maps input strings to
    # arrays of output strings.
    # Param `suggestion.sourceWords` is an array of words defining the source
    # (e.g., the words in the morpheme break value).
    getSuggestedValues: (suggestion) ->
      # `suggestedValuesArray` will be an array of arrays, where the sub-arrays
      # contain the set of string suggestions for each word in the source, in
      # the same order as the source.
      suggestedValuesArray = []
      for word in suggestion.sourceWords
        try
          wordSuggestedValuesArray = suggestion.suggestion[word]
        catch
          # If we have no suggestion, use the input as the output.
          wordSuggestedValuesArray = [word]
        if wordSuggestedValuesArray and
        @utils.type(wordSuggestedValuesArray) is 'array' and
        wordSuggestedValuesArray.length > 0
          suggestedValuesArray.push wordSuggestedValuesArray
        else
          # If our suggestion is not an array with at least one item, use the
          # input as the output.
          suggestedValuesArray.push [word]
      # Since the underlying form of a word can have multiple surface forms,
      # our sentence-level suggestions must contain all possible combinations
      # of surface forms (that match the order of source words, of course).
      @getCombinations suggestedValuesArray

    # Take something like `[['a', 'b'], ['c', 'd', 'e'], ['f']]` and return
    # something like `[ 'a c f', 'a d f', 'a e f', 'b c f', 'b d f', 'b e f']`.
    getCombinations: (suggestedValuesArray) ->
      if suggestedValuesArray.length is 0
        # This should never happen.
        []
      else if suggestedValuesArray.length is 1
        suggestedValuesArray[0]
      else
        result = []
        prefixes = suggestedValuesArray[0]
        suffixes = @getCombinations suggestedValuesArray[1...]
        for prefix in prefixes
          for suffix in suffixes
            result.push "#{prefix} #{suffix}"
        result


    ############################################################################
    # Suggestion ISSUER logic
    ############################################################################

    listenForParserTaskSetChange: ->
      @listenTo globals.applicationSettings, 'change:parserTaskSet',
        @parserTaskSetChanged

    # Our global parser task set model has changed. Since this might affect us,
    # we refresh our state relative to our parser (if we have one).
    parserTaskSetChanged: ->
      @stopListeningToParser()
      @parser = @getParser()
      @listenToParser()
      for targetField in @targetFields
        @model.trigger "#{targetField}:turnOffSuggestions"

    # This number is how long the user must be idle for (in terms of input into
    # the transcription field) in order for us to allow parse requests to the
    # server to be possible.
    idle: 500

    # Tell our parser to issue a parse request to the server, but only if the
    # user has been idle for a sufficient period of time.
    requestParseCheck: ->
      if (((new Date()) - @lastInput) > @idle) then @requestParse()

    # Request parses for the words typed into our transcription-type textarea
    # that we haven't already requested parses for.
    requestParse: ->
      if @parser
        wordsToParse =
          (w for w in @wordsSeen when w not in @parseRequested)
        if (wordsToParse.length > 0) and
        (not @parseRequestPending)
          @parser.parse wordsToParse

    # Get the words that are currently in our value.
    getCurrentWords: ->
      (w for w in \
        @model.get(@attribute).trim().normalize('NFD').split(/\s+/) \
        when w)

    # Trigger an event on the (form) model that other fields (i.e., the
    # morpheme break and morpheme gloss fields) can listen for. The argument
    # passed to listeners is an object that contains the suggestion for the
    # recipient field as well as information about the source, the target, the
    # suggester FST resource, etc.
    triggerSuggestion: ->
      morphemeBreakSuggestion = {}
      morphemeGlossSuggestion = {}
      currentWords = @getCurrentWords()
      for word in currentWords
        parse = @parseCache[word]
        if parse
          [morphemeBreakParse, morphemeGlossParse] = @parseParse parse
          morphemeBreakSuggestion[word] = morphemeBreakParse
          morphemeGlossSuggestion[word] = morphemeGlossParse
        else
          # Suggest simply using the word's transcription value (i.e., the
          # input) for morpheme break and '?' for the gloss, if the parser
          # resource has not given us any suggestions.
          morphemeBreakSuggestion[word] = word
          morphemeGlossSuggestion[word] = '?'
      suggester = "Morphological Parser #{@parser.id}"
      morphemeBreakPayload =
        source: @attribute
        sourceWords: currentWords
        target: 'morpheme_break'
        suggestion: morphemeBreakSuggestion
        suggester: suggester
      morphemeGlossPayload =
        source: @attribute
        sourceWords: currentWords
        target: 'morpheme_gloss'
        suggestion: morphemeGlossSuggestion
        suggester: suggester
      @model.trigger "morpheme_break:suggestion", morphemeBreakPayload
      @model.trigger "morpheme_gloss:suggestion", morphemeGlossPayload

    # Use the info in `globals.applicationSettings.get('parserTaskSet') to get
    # a parser model for this transcription-type field. If there is no parser
    # assigned to this transcription (i.e., in app settings), then return
    # `null`.
    getParser: ->
      # See if we can get global parser-related tasks.
      try
        @parserRelatedTasks = globals.applicationSettings.get('parserTaskSet')
      catch
        @parserRelatedTasks = null
      if @parserRelatedTasks
        parser = @parserRelatedTasks.get "#{@attribute}_parser"
        if parser
          if @_parserModel and @_parserModel.get('UUID') is parser.UUID
            @_parserModel
          else
            new MorphologicalParserModel parser
      else
        null

    listenToParser: ->
      if @parser
        @listenTo @parser, "parseStart", @parseStart
        @listenTo @parser, "parseEnd", @parseEnd
        @listenTo @parser, "parseSuccess", @parseSuccess
        @listenTo @parser, "parseFail", @parseFail

    stopListeningToParser: ->
      if @parser then @stopListening @parser

    parseStart: ->
      @parseRequestPending = true

    parseEnd: ->
      @parseRequestPending = false

    parseSuccess: (response) ->
      for word, parse of response
        @parseCache[word] = parse
        @parseRequested.push word
      @triggerSuggestion()

    parseFail: (error) ->
      console.log "attempted 'parse' request with #{@attribute}'s parser failed
        ..."
      console.log error

    # Return the morpheme delimiters that the (OLD) backend that we are
    # connected to is assuming.
    getDelims: -> ['-', '=']

    # Return a regex that can split parses based on delimiters while retaining
    # those delimiters.
    getSplitterRegex: ->
      if not @_splitter
        @_splitter = new RegExp "(#{@getDelims().join '|'})"
      @_splitter

    # Parse the parse, i.e., take a string like 'nit⦀1⦀agra-ihpiyi⦀dance⦀vai'
    # and return an array like ['nit-ihpiyi', '1-dance'].
    parseParse: (parse) ->
      rareDelimiter = @parser.get 'morphology_rare_delimiter'
      shapes = []
      glosses = []
      for morphemeTriplet in parse.split @getSplitterRegex()
        if morphemeTriplet in @getDelims()
          shapes.push morphemeTriplet
          glosses.push morphemeTriplet
        else
          [shape, gloss, ...] = morphemeTriplet.split rareDelimiter
          shapes.push shape
          glosses.push gloss
      [shapes.join(''), glosses.join('')]

    # These are the fields that our parse suggestions will be directed to.
    getTargetFields: -> ['morpheme_break', 'morpheme_gloss']

