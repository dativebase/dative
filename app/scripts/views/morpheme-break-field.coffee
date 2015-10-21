define [
  './textarea-field'
  './suggestion-receiver-field'
  './../models/phonology'
  './../models/morphology'
  './../templates/field-suggestible'
  './../utils/globals'
], (TextareaFieldView, SuggestionReceiverFieldView, PhonologyModel,
  MorphologyModel, suggestibleFieldTemplate, globals) ->

  # Morpheme Break Field View
  # -------------------------
  #
  # The morpheme break field is both a suggestion maker and receiver:
  #
  # 1. it uses phonologies to make suggestions to transcription fields;
  # 2. it receives suggestions from transcription fields (based on parsers).
  #
  # As a suggester, the morpheme break field does the following.
  #
  # 1. Uses a phonology to suggest one or more transcription values (for various
  #    transcription fields), given the morpheme break value that the user has
  #    entered.
  #
  # 2. Uses a morphology to alert the user when it does not recognize a word
  #    that the user has entered.
  #
  #    subcase a. morphology does not recognize a word's category string.
  #    subcase b. morphology does not recognize a word's exact morphological
  #               analysis.
  #

  class MorphemeBreakFieldView extends TextareaFieldView

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

      @mixinSuggestionReceiverFieldMethods()

      ##########################################################################
      # Suggestion RECEIVER attributes
      ##########################################################################

      # When set to `true` this means that a received suggestion is
      # responsible for the current value in our <textarea>. When set to
      # `false` (the default), this means that the user is responsible for this
      # value; this prevents suggestions from overwriting user-specified input.
      @systemSuggested = false

      # This array will hold suggestions (strings) for this morpheme break
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
      # morpheme_break input field. This is an array of all of the unique words
      # that the user has typed into the morpheme_break field.
      @wordsSeen = []

      # The `@...Requested` attributes are arrays of words that we have sent to
      # the server for processing, e.g., for phonologization or recognition.
      @toTranscriptionRequested = []
      @toPhoneticTranscriptionRequested = []
      @toNarrowPhoneticTranscriptionRequested = []
      @recognizeRequested = []

      # The `@...Cache` attributes are objects that match input words (from the
      # user) to output from the server, e.g., phonologizations or recognition
      # information.
      @toTranscriptionCache = {}
      @toPhoneticTranscriptionCache = {}
      @toNarrowPhoneticTranscriptionCache = {}
      @recognizeCache = {}

      # This method will valuate the attributes that hold Phonology/Morphology
      # models used in processing user input to the morpheme_break field. These
      # attributes are valuated based on the values in
      # `globals.applicationSettings.get('parserTaskSet')`.
      @getFSTModels()

      @toTranscriptionRequestPending = false
      @toPhoneticTranscriptionRequestPending = false
      @toNarrowPhoneticTranscriptionRequestPending = false
      @recognizeRequestPending = false

      # Return an array of field names that we may target, i.e., send
      # suggestions to.
      @targetFields = @getTargetFields()

    listenToEvents: ->
      super

      # Something is offering us a suggestion for what our morpheme break value
      # should be.
      @listenTo @model, "#{@attribute}:suggestion", @suggestionReceived

      # Something is telling us to hide our current suggestions. This happens
      # when a transcription field recognizes that its morphological parser
      # has been changed to `null`.
      @listenTo @model, "#{@attribute}:turnOffSuggestions", @turnOffSuggestions

      # The input view's <textarea> has resized itself, so we respond by
      # resizing our .suggestions <div>.
      @listenTo @model, 'textareaWidthResize', @resizeAndPositionSuggestionsDiv

      # If we have any FST-based models for morpheme break processing, this
      # method will cause us to listen to their relevant events.
      @listenToFSTModels()
      @listenForParserTaskSetChange()

    render: ->
      @lastInput = new Date()
      @setIntervalId = setInterval (=> @issueRequestsCheck()), 500
      super
      @

    guify: ->
      super
      @guifyForSuggestions()

    onClose: -> clearInterval @setIntervalId

    # Respond to an 'input' event in our <textarea>: user is entering data.
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

      @triggerSuggestions()
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
        @[method] = SuggestionReceiverFieldView::[method]

    ############################################################################
    # Morpheme Break-specific suggestion receiver logic
    ############################################################################

    # Given the suggestor's `suggestion` object, return a string that is the
    # suggestion for this field. Note that at present we are assuming that
    # the transcription field that is giving us this suggestion (via a parser)
    # has sent us a one-to-one mapping from word transcriptions to optimal
    # parses. Therefore no fancy combinatorics are needed (cf. the
    # transcription-base-field.coffee view) in order to return a suggested value.
    # Param `suggestion.suggestion` is an object that maps input strings (i.e.,
    # transcriptions) to output strings, i.e., (morpheme break values).
    # Param `suggestion.sourceWords` is an array of words defining the source
    # (e.g., the words in the transcription-type value).
    getSuggestedValues: (suggestion) ->
      try
        suggestedValue = []
        for word in suggestion.sourceWords
          suggestedValue.push suggestion.suggestion[word]
        [suggestedValue.join ' ']
      catch
        []

    # Get the new width for the suggestions div given the width of the textarea
    # that it goes with as input.
    getNewWidth: (textareaWidth) ->
      textareaWidth + 19

    # Return `true` if the supplied `value` (from the user) is in the suggested
    # values. This is field-specific because different fields can decide what
    # it means for a value to match any of the suggested ones, e.g., maybe
    # capitalization is not important.
    userValueInSuggestedValues: (value) ->
      value in @suggestedValues or
      @utils.singleSpace(value) in @suggestedValues


    ############################################################################
    # Suggestion ISSUER logic
    ############################################################################

    listenForParserTaskSetChange: ->
      @listenTo globals.applicationSettings, 'change:parserTaskSet',
        @parserTaskSetChanged

    parserTaskSetChanged: ->
      @stopListeningToFSTModels()
      @getFSTModels()
      @listenToFSTModels()
      for targetField in @targetFields
        @model.trigger "#{targetField}:turnOffSuggestions"

    # Trigger events containing suggestions (e.g., for a transcription field's
    # value), as is relevant, given our phonologies/morphology.
    triggerSuggestions: ->
      if @toTranscriptionPhonology then @triggerToTranscriptionSuggestion()
      if @toPhoneticTranscriptionPhonology
        @triggerToPhoneticTranscriptionSuggestion()
      if @toNarrowPhoneticTranscriptionPhonology
        @triggerToNarrowPhoneticTranscriptionSuggestion()

    # This number is how long the user must be idle for (in terms of input into
    # the morpheme_break field) in order for us to allow requests to the server
    # to be possible.
    idle: 500

    # Tell our FST-based models to issue processing requests to the server, but
    # only if the user has been idle for a sufficient period of time.
    issueRequestsCheck: ->
      if (((new Date()) - @lastInput) > @idle) then @issueRequests()

    # Tell our FST-based models to issue processing requests to the server.
    # That is, tell phonologies to issue "apply down" requests and morphologies
    # to issue "apply up" requests.
    issueRequests: ->
      @phonologizeToTranscription()
      @phonologizeToPhoneticTranscription()
      @phonologizeToNarrowPhoneticTranscription()
      @recognizeAnalysis()

    # Get the words that are currently in the morpheme_break value.
    getCurrentWords: ->
      (w for w in \
        @model.get(@attribute).trim().normalize('NFD').split(/\s+/) \
        when w)

    # Trigger an event on the (form) model that other fields (e.g., the
    # transcription field) can listen for. The argument passed to listeners is
    # an object that contains the suggestion for the recipient field.
    triggerSuggestion: (targetField, cacheAttribute, suggester) ->
      suggestion = {}
      currentWords = @getCurrentWords()
      for word in currentWords
        wordSuggestion = @[cacheAttribute][word]
        if wordSuggestion
          suggestion[word] = wordSuggestion
        else
          # Suggest simply using the morpheme_break word representation if the
          # FST-based resource has not given us any suggestions.
          suggestion[word] = [word]
      payload =
        source: 'morpheme_break'
        sourceWords: currentWords
        target: targetField
        suggestion: suggestion
        suggester: suggester
      @model.trigger "#{targetField}:suggestion", payload

    # Use the info in `globals.applicationSettings.get('parserTaskSet') to get
    # models for any FST-based resources that are relevant to processing user
    # input into the morpheme_break field.
    getFSTModels: ->
      # See if we can get global parser-related tasks.
      try
        @parserRelatedTasks = globals.applicationSettings.get('parserTaskSet')
      catch
        @parserRelatedTasks = null
      if @parserRelatedTasks
        @toTranscriptionPhonology =
          @parserRelatedTasks.get 'to_transcription_phonology'
        @toPhoneticTranscriptionPhonology =
          @parserRelatedTasks.get 'to_phonetic_transcription_phonology'
        @toNarrowPhoneticTranscriptionPhonology =
          @parserRelatedTasks.get 'to_narrow_phonetic_transcription_phonology'
        @recognizerMorphology = @parserRelatedTasks.get 'recognizer_morphology'
        if @toTranscriptionPhonology
          @toTranscriptionPhonology = @object2model(
            @toTranscriptionPhonology, 'phonology',
            'toTranscriptionPhonology')
        if @toPhoneticTranscriptionPhonology
          @toPhoneticTranscriptionPhonology = @object2model(
            @toPhoneticTranscriptionPhonology, 'phonology',
            'toPhoneticTranscriptionPhonology')
        if @toNarrowPhoneticTranscriptionPhonology
          @toNarrowPhoneticTranscriptionPhonology = @object2model(
            @toNarrowPhoneticTranscriptionPhonology, 'phonology',
            'toNarrowPhoneticTranscriptionPhonology')
        if @recognizerMorphology
          @recognizerMorphology = @object2model(@recognizerMorphology,
            'morphology', 'recognizerMorphology')
      else
        @toTranscriptionPhonology = null
        @toPhoneticTranscriptionPhonology = null
        @toNarrowPhoneticTranscriptionPhonology = null
        @recognizerMorphology = null

    # Listen to the relevant events of any FST-based resource models that we
    # may be using to process user input into the morpheme_break field.
    listenToFSTModels: ->
      if @toTranscriptionPhonology then @listenToToTranscriptionPhonology()
      if @toPhoneticTranscriptionPhonology
        @listenToToPhoneticTranscriptionPhonology()
      if @toNarrowPhoneticTranscriptionPhonology
        @listenToToNarrowPhoneticTranscriptionPhonology()
      if @recognizerMorphology then @listenToRecognizerMorphology()

    # Stop listening to any FST-based resource models that we may already be
    # listening to.
    stopListeningToFSTModels: ->
      if @toTranscriptionPhonology then @stopListening @toTranscriptionPhonology
      if @toPhoneticTranscriptionPhonology
        @stopListening @toPhoneticTranscriptionPhonology
      if @toNarrowPhoneticTranscriptionPhonology
        @stopListening @toNarrowPhoneticTranscriptionPhonology
      if @recognizerMorphology then @stopListening @recognizerMorphology

    # Given an object `object`, the name of a resource `resource`, and the
    # name of an attribute on `@`, instantiate a model class using `object`,
    # assign it to the appropriate attribute on `@`, and return it, or use the
    # pre-existing model, if possible.
    object2model: (object, resource, attributeName) ->
      modelAttribute = "_#{attributeName}Model"
      if @[modelAttribute] and @[modelAttribute].get('UUID') is object.UUID
        @[modelAttribute]
      else
        c = if resource is 'phonology' then PhonologyModel else MorphologyModel
        @[modelAttribute] = new c(object)
        @[modelAttribute]

    # Use morpheme break value to generate a transcription using the
    # appropriate phonology resource.
    phonologizeToTranscription: ->
      if @toTranscriptionPhonology
        wordsToPhonologize =
          (w for w in @wordsSeen when w not in @toTranscriptionRequested)
        if (wordsToPhonologize.length > 0) and
        (not @toTranscriptionRequestPending)
          @toTranscriptionPhonology.applyDown wordsToPhonologize

    # Use morpheme break value to generate a phonetic transcription using the
    # appropriate phonology resource.
    phonologizeToPhoneticTranscription: ->
      if @toPhoneticTranscriptionPhonology
        wordsToPhonologize = (w for w in @wordsSeen \
          when w not in @toPhoneticTranscriptionRequested)
        if (wordsToPhonologize.length > 0) and
        (not @toPhoneticEqualsToTranscription()) and
        (not @toPhoneticTranscriptionRequestPending)
          @toPhoneticTranscriptionPhonology.applyDown wordsToPhonologize

    # Return `true` if `@toPhoneticTranscriptionPhonology` is equal to
    # `@toTranscriptionPhonology`. If there is equality, then we piggy-back on
    # the requests of the transcription phonology.
    toPhoneticEqualsToTranscription: ->
      if @toTranscriptionPhonology
        @toTranscriptionPhonology.id is @toPhoneticTranscriptionPhonology.id
      else
        false

    # Return `true` if `@toNarrowPhoneticTranscriptionPhonology` is equal to
    # either of the other two phonologies. If there is equality, then we
    # piggy-back on the requests of one of the other phonologies.
    toNarrowEqualsOther: ->
      if @toTranscriptionPhonology and
      @toTranscriptionPhonology.id is @toNarrowPhoneticTranscriptionPhonology.id
        true
      else if @toPhoneticTranscriptionPhonology and
      @toPhoneticTranscriptionPhonology.id is @toNarrowPhoneticTranscriptionPhonology.id
        true
      else
        false

    # Use morpheme break value to generate a narrow phonetic transcription
    # using the appropriate phonology resource.
    phonologizeToNarrowPhoneticTranscription: ->
      if @toNarrowPhoneticTranscriptionPhonology
        wordsToPhonologize = (w for w in @wordsSeen \
          when w not in @toNarrowPhoneticTranscriptionRequested)
        if (wordsToPhonologize.length > 0) and
        (not @toNarrowEqualsOther()) and
        (not @toNarrowPhoneticTranscriptionRequestPending)
          @toNarrowPhoneticTranscriptionPhonology.applyDown wordsToPhonologize

    # Alert the user if their morpheme break cannot be recognized using the
    # specified (recognizer) morphology.
    # TODO: make this actually work; right now it's just logging to the console.
    recognizeAnalysis: ->
      if @recognizerMorphology
        wordsToRecognize = (w for w in @wordsSeen \
          when w not of @recognizeRequested)
        if (wordsToRecognize.length > 0) and
        (not @recognizeRequestPending)
          console.log "we will request recognition of these words:
            #{wordsToRecognize.join ', '}"
          # TODO: I don't know if you can pass an array to `applyUp` yet ...
          # @recognizerMorphology.applyUp wordsToRecognize

    # These are the fields that our parse suggestions will be directed to.
    getTargetFields: ->
      [
        'transcription',
        'phonetic_transcription',
        'narrow_phonetic_transcription'
      ]


    ############################################################################
    # Listen to our phonologies and morphology.
    ############################################################################

    # Listen to our "to phonetic transcription" phonology's events
    # related to making "apply down" requests.
    listenToToTranscriptionPhonology: ->
      @listenTo @toTranscriptionPhonology, "applyDownStart",
        @toTranscriptionPhonologyApplyDownStart
      @listenTo @toTranscriptionPhonology, "applyDownEnd",
        @toTranscriptionPhonologyApplyDownEnd
      @listenTo @toTranscriptionPhonology, "applyDownFail",
        @toTranscriptionPhonologyApplyDownFail
      @listenTo @toTranscriptionPhonology, "applyDownSuccess",
        @toTranscriptionPhonologyApplyDownSuccess

    # Listen to our "to phonetic transcription" phonology's events
    # related to making "apply down" requests.
    listenToToPhoneticTranscriptionPhonology: ->
      @listenTo @toPhoneticTranscriptionPhonology, "applyDownStart",
        @toPhoneticTranscriptionPhonologyApplyDownStart
      @listenTo @toPhoneticTranscriptionPhonology, "applyDownEnd",
        @toPhoneticTranscriptionPhonologyApplyDownEnd
      @listenTo @toPhoneticTranscriptionPhonology, "applyDownFail",
        @toPhoneticTranscriptionPhonologyApplyDownFail
      @listenTo @toPhoneticTranscriptionPhonology, "applyDownSuccess",
        @toPhoneticTranscriptionPhonologyApplyDownSuccess

    # Listen to our "to narrow phonetic transcription" phonology's events
    # related to making "apply down" requests.
    listenToToNarrowPhoneticTranscriptionPhonology: ->
      @listenTo @toNarrowPhoneticTranscriptionPhonology, "applyDownStart",
        @toNarrowPhoneticTranscriptionPhonologyApplyDownStart
      @listenTo @toNarrowPhoneticTranscriptionPhonology, "applyDownEnd",
        @toNarrowPhoneticTranscriptionPhonologyApplyDownEnd
      @listenTo @toNarrowPhoneticTranscriptionPhonology, "applyDownFail",
        @toNarrowPhoneticTranscriptionPhonologyApplyDownFail
      @listenTo @toNarrowPhoneticTranscriptionPhonology, "applyDownSuccess",
        @toNarrowPhoneticTranscriptionPhonologyApplyDownSuccess

    # Listen to our recognizer morphology's events related to making "apply up"
    # requests.
    listenToRecognizerMorphology: ->
      @listenTo @recognizerMorphology, "applyUpStart",
        @recognizerMorphologyApplyUpStart
      @listenTo @recognizerMorphology, "applyUpEnd",
        @recognizerMorphologyApplyUpEnd
      @listenTo @recognizerMorphology, "applyUpFail",
        @recognizerMorphologyApplyUpFail
      @listenTo @recognizerMorphology, "applyUpSuccess",
        @recognizerMorphologyApplyUpSuccess


    ############################################################################
    # Event handlers for "to transcription phonology"
    ############################################################################

    toTranscriptionPhonologyApplyDownStart: ->
      @toTranscriptionRequestPending = true

    toTranscriptionPhonologyApplyDownEnd: ->
      @toTranscriptionRequestPending = false

    toTranscriptionPhonologyApplyDownFail: (error) ->
      console.log "attempted 'apply down' request with
        `@toTranscriptionPhonology` failed ..."
      console.log error

    toTranscriptionPhonologyApplyDownSuccess: (response) ->
      for uf, sfSet of response
        @toTranscriptionCache[uf] = sfSet
        @toTranscriptionRequested.push uf
      @triggerToTranscriptionSuggestion()
      @cacheAndTriggerSubordinatePhonologies response

    # If the "to phonetic" or "to narrow phonetic" phonologies are the same as
    # the "to transcription" one, then we populate those phonologies' caches
    # with our response and we trigger their suggestion events. This prevents
    # redundant requests to the same phonology on the server.
    cacheAndTriggerSubordinatePhonologies: (response) ->
      if @toPhoneticTranscriptionPhonology and
      @toPhoneticTranscriptionPhonology.id is @toTranscriptionPhonology.id
        for uf, sfSet of response
          @toPhoneticTranscriptionCache[uf] = sfSet
          @toPhoneticTranscriptionRequested.push uf
        @triggerToPhoneticTranscriptionSuggestion()
      if @toNarrowPhoneticTranscriptionPhonology and
      @toNarrowPhoneticTranscriptionPhonology.id is @toTranscriptionPhonology.id
        for uf, sfSet of response
          @toNarrowPhoneticTranscriptionCache[uf] = sfSet
          @toNarrowPhoneticTranscriptionRequested.push uf
        @triggerToNarrowPhoneticTranscriptionSuggestion()

    triggerToTranscriptionSuggestion: ->
      suggester = "Phonology #{@toTranscriptionPhonology.id}"
      @triggerSuggestion 'transcription', 'toTranscriptionCache', suggester


    ############################################################################
    # Event handlers for "to phonetic transcription phonology"
    ############################################################################

    toPhoneticTranscriptionPhonologyApplyDownStart: ->
      @toPhoneticTranscriptionRequestPending = true

    toPhoneticTranscriptionPhonologyApplyDownEnd: ->
      @toPhoneticTranscriptionRequestPending = false

    toPhoneticTranscriptionPhonologyApplyDownFail: (error) ->
      console.log "attempted 'apply down' request with
        `@toPhoneticTranscriptionPhonology` failed ..."
      console.log error

    toPhoneticTranscriptionPhonologyApplyDownSuccess: (response) ->
      for uf, sfSet of response
        @toPhoneticTranscriptionCache[uf] = sfSet
        @toPhoneticTranscriptionRequested.push uf
      @triggerToPhoneticTranscriptionSuggestion()
      @cacheAndTriggerSubordinatePhonology response

    # If the "to narrow phonetic" phonology is the same as the "to phonetic"
    # one, then we populate its cache with our response and we trigger its
    # suggestion event. This prevents redundant requests to the same phonology
    # on the server.
    cacheAndTriggerSubordinatePhonology: (response) ->
      if @toNarrowPhoneticTranscriptionPhonology and
      @toNarrowPhoneticTranscriptionPhonology.id is @toPhoneticTranscriptionPhonology.id
        for uf, sfSet of response
          @toNarrowPhoneticTranscriptionCache[uf] = sfSet
          @toNarrowPhoneticTranscriptionRequested.push uf
        @triggerToNarrowPhoneticTranscriptionSuggestion()

    triggerToPhoneticTranscriptionSuggestion: ->
      suggester = "Phonology #{@toPhoneticTranscriptionPhonology.id}"
      @triggerSuggestion 'phonetic_transcription',
        'toPhoneticTranscriptionCache', suggester


    ############################################################################
    # Event handlers for "to narrow phonetic transcription phonology"
    ############################################################################

    toNarrowPhoneticTranscriptionPhonologyApplyDownStart: ->
      @toNarrowPhoneticTranscriptionRequestPending = true

    toNarrowPhoneticTranscriptionPhonologyApplyDownEnd: ->
      @toNarrowPhoneticTranscriptionRequestPending = false

    toNarrowPhoneticTranscriptionPhonologyApplyDownFail: (error) ->
      console.log "attempted 'apply down' request with
        `@toNarrowPhoneticTranscriptionPhonology` failed ..."
      console.log error

    toNarrowPhoneticTranscriptionPhonologyApplyDownSuccess: (response) ->
      for uf, sfSet of response
        @toNarrowPhoneticTranscriptionCache[uf] = sfSet
        @toNarrowPhoneticTranscriptionRequested.push uf
      @triggerToNarrowPhoneticTranscriptionSuggestion()

    triggerToNarrowPhoneticTranscriptionSuggestion: ->
      suggester = "Phonology #{@toNarrowPhoneticTranscriptionPhonology.id}"
      @triggerSuggestion 'narrow_phonetic_transcription',
        'toNarrowPhoneticTranscriptionCache', suggester

    ############################################################################
    # Event handlers for "recognizer morphology"
    ############################################################################

    recognizerMorphologyApplyUpStart: ->
      @recognizeRequestPending = true

    recognizerMorphologyApplyUpEnd: ->
      @recognizeRequestPending  = false

    recognizerMorphologyApplyUpFail: (error) ->
      console.log "attempted 'apply up' request with
        `@recognizerMorphology` failed ..."
      console.log error

    recognizerMorphologyApplyUpSuccess: (response) ->
      console.log 'the recognizer morphology issued a successful apply up
        request, but we still need to figure out what we want to do with it!'

