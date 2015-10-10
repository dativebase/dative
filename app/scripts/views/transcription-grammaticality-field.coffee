define [
  'backbone'
  './field'
  './select-textarea-input'
], (Backbone, FieldView, SelectTextareaInputView) ->

  # Transcription Grammaticality Field View
  # ---------------------------------------
  #
  # A field view specifically for a grammaticality <select> and a transcription
  # <textarea>. (Compare to the similar utterance-judgement-field view.)

  class TranscriptionGrammaticalityFieldView extends FieldView

    # Default is to call `set` on the model any time a field input changes.
    events:
      'change':                'setToModel' # fires when multi-select changes
      'input':                 'userInput' # fires when an input, textarea or date-picker changes
      'selectmenuchange':      'setToModel' # fires when a selectmenu changes
      'menuselect':            'setToModel' # fires when the tags multi-select changes (not working?...)
      'keydown .ms-container': 'multiselectKeydown'
      'keydown textarea, input, .ui-selectmenu-button, .ms-container':
                               'controlEnterSubmit'

    listenToEvents: ->
      super
      @listenTo @model, 'transcription:suggestion', @suggestionReceived

    userInput: ->
      @setToModel()
      @systemSuggested = false

    initialize: (options) ->
      super options
      @systemSuggested = false

    suggestionReceived: (suggestion) ->
      $transcriptionInput = @$('textarea[name=transcription]').first()
      currentValue = $transcriptionInput.val().trim()
      suggestedValue = @getSuggestedValue suggestion
      if @systemSuggested or (not currentValue)
        @systemSuggested = true
        $transcriptionInput.val suggestedValue
        @setToModel()

    getSuggestedValue: (suggestion) ->
      suggestedValue = []
      for word in suggestion.sourceWords
        try
          suggestedWord = suggestion.suggestion[word][0]
        catch
          suggestedWord = word
        if suggestedWord
          suggestedValue.push suggestedWord
        else
          suggestedValue.push word
      suggestedValue.join ' '

    # Override this in a subclass to swap in a new input view, e.g., one based
    # on a <select> or an <input[type=text]>, etc.
    getInputView: ->
      new SelectTextareaInputView @context

    # `FieldView` will call this to set `@context` in the constructor.
    # The `SelectTextareaInputView` instance needs to know how to label/valuate
    # its <select> and <textarea>.
    getContext: ->
      selectAttribute = 'grammaticality'
      selectOptionsAttribute = 'grammaticalities'
      defaultContext = super()
      _.extend(defaultContext,

        selectOptionsAttribute: selectOptionsAttribute
        selectAttribute: selectAttribute
        selectName: @getName selectAttribute
        selectClass: @getClass selectAttribute
        selectTitle: @getTooltip selectAttribute
        selectValue: @getValue selectAttribute

        textareaName: defaultContext.name
        textareaClass: defaultContext.class
        textareaTitle: defaultContext.title
        textareaValue: defaultContext.value
      )

    getValueFromDOM: ->
      value = super
      for k, v of value
        if not v then value[k] = ''
      value

