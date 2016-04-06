define [
  './transcription-base-field'
  './select-textarea-input'
  './../utils/globals'
], (TranscriptionBaseFieldView, SelectTextareaInputView, globals) ->

  # Transcription Grammaticality Field View
  # ---------------------------------------
  #
  # A field view specifically for a grammaticality <select> and a transcription
  # <textarea>. (Compare to the similar utterance-judgement-field view.)

  class TranscriptionGrammaticalityFieldView extends TranscriptionBaseFieldView

    listenToEvents: ->
      super
      # If the available grammaticality options change in `globals` we refresh
      # ourselves so that that change is reflected in the grammaticality selectmenu.
      # TODO: why isn't this working?
      @listenTo globals, "change:grammaticalities", @refresh

      # One of our fellow transcription-type fields is telling us to validate.
      @listenTo @model, 'transcriptionShouldValidate', @validate

      @listenTo @model, 'warning:orthographic_validation',
        @invalidFieldValueWarning

    # We have received a warning from our model that the transcription value is
    # invalid.
    invalidFieldValueWarning: (msg=null) ->
      if msg
        @$('.dative-field-warnings-container').show()
        @$('.dative-field-validation-warning-message').text "Warning: #{msg}"
      else
        @$('.dative-field-warnings-container').hide()

    setToModel: ->
      super
      if @submitAttempted
        @model.trigger 'phoneticTranscriptionShouldValidate'
        @model.trigger 'narrowPhoneticTranscriptionShouldValidate'
        @model.trigger 'morphemeBreakShouldValidate'
      else
        # We call validate on the model here just so that warning events can be
        # triggered, if applicable.
        @model.validate()

    getMarginLeft: -> if @addUpdateType is 'add' then '34.5%' else '37.5%'

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

