define [
  './textarea-field'
  './suggestion-receiver-field'
  './../templates/field-suggestible'
  './../utils/globals'
], (TextareaFieldView, SuggestionReceiverFieldView, suggestibleFieldTemplate,
  globals) ->

  # Morpheme Gloss Field View
  # -------------------------
  #
  # The morpheme gloss field is a suggestion receiver: transcription fields
  # will suggest values for it. The morpheme break field may give it
  # suggestions too.

  class MorphemeGlossFieldView extends TextareaFieldView

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

      # This array will hold suggestions (strings) for this morpheme gloss
      # field.
      @suggestedValues = []

      # This will hold any suggestion object that we may receive.
      @suggestionUnaltered = null

      # Indicates whether the suggestions are visible in the UI.
      @suggestionsVisible = false

    listenToEvents: ->
      super

      # Something is offering us a suggestion for what our morpheme gloss value
      # should be.
      @listenTo @model, "#{@attribute}:suggestion", @suggestionReceived

      # Something is telling us to hide our current suggestions. This happens
      # when a transcription field recognizes that its morphological parser
      # has been changed to `null`.
      @listenTo @model, "#{@attribute}:turnOffSuggestions", @turnOffSuggestions

      # The input view's <textarea> has resized itself, so we respond by
      # resizing our .suggestions <div>.
      @listenTo @model, 'textareaWidthResize', @resizeAndPositionSuggestionsDiv

    render: ->
      @lastInput = new Date()
      super
      @

    guify: ->
      super
      @guifyForSuggestions()

    # Respond to an 'input' event in our <textarea>: user is entering data.
    respondToInput: ->
      # The super-class would have called `setToModel` on an input event, so we
      # do that here too.
      @setToModel()

      # Remember the timestamp of the last input event; this info will be used
      # to decide when we should make requests to the server.
      @lastInput = new Date()

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
    # Morpheme Gloss-specific suggestion receiver logic
    ############################################################################

    # Given the suggestor's `suggestion` object, return a string that is the
    # suggestion for this field. Note that at present we are assuming that
    # the transcription field that is giving us this suggestion (via a parser)
    # has sent us a one-to-one mapping from word transcriptions to optimal
    # parses. Therefore no fancy combinatorics are needed (cf. the
    # transcription-base-field.coffee view) in order to return a suggested value.
    # Param `suggestion.suggestion` is an object that maps input strings (i.e.,
    # transcriptions) to output strings, i.e., (morpheme gloss values).
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

