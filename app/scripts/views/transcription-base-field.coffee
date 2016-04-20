define [
  './field'
  './suggestion-receiver-field'
  './../models/morphological-parser'
  './../templates/field-suggestible-warnings'
  './../utils/globals'
], (FieldView, SuggestionReceiverFieldView,  MorphologicalParserModel,
  suggestibleWarningsFieldTemplate, globals) ->

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
      'keydown textarea':      'keyboardInterceptTextareaKeydownSuggestible'
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
      'focusin textarea':      'signalActiveKeyboard'

    template: suggestibleWarningsFieldTemplate

    initialize: (options) ->
      super options

      @mixinSuggestionReceiverFieldMethods()

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

      @keyboard = @getKeyboard()

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

      if @parser then @triggerSuggestions()
      @systemSuggested = false
      @alertIncongruity()


    ############################################################################
    # Suggestion RECEIVER logic
    ############################################################################

    # Call this early on in `initialize` above in order to take useful methods
    # from the suggestion receiver field.
    mixinSuggestionReceiverFieldMethods: ->
      methodsWeWant =[
        'guifyForSuggestions'
        'hoverStateSuggestionOn'
        'hoverStateSuggestionOff'
        'myControlEnterSubmit'
        'suggestionReceived'
        'turnOffSuggestions'
        'maxNoSuggestions'
        'addSuggestionsToSuggestionsDiv'
        'resizeAndPositionSuggestionsDiv'
        'getSuggestedValuesHTML'
        'alertIncongruity'
        'suggestionClicked'
        'toggleSuggestions'
        'openSuggestionsAnimateCheck'
        'closeSuggestionsAnimate'
        'suggestionsKeyboardControl'
        'toggleSuggestionsButtonState'
        'showSuggestionsButtonCheck'
        'hideSuggestionsButtonCheck'
      ]
      for method in methodsWeWant
        if method is 'myControlEnterSubmit'
          @mixinMyControlEnterSubmit = SuggestionReceiverFieldView::[method]
        else
          @[method] = SuggestionReceiverFieldView::[method]

    getNewWidth: (textareaWidth) ->
      if @attribute is 'transcription'
        newWidth = textareaWidth + 19.5
      else
        newWidth = textareaWidth + 19

    removePunctuation: (value) ->
      value.replace(/['"“”‘’,.!?]/g, '')

    userValueInSuggestedValues: (value) ->
      value in @suggestedValues or
      value.toLowerCase() in @suggestedValues or
      @removePunctuation(value.toLowerCase()) in @suggestedValues or
      @utils.singleSpace(@removePunctuation(value.toLowerCase())) in @suggestedValues

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
    triggerSuggestions: ->
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
      @triggerSuggestions()

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

