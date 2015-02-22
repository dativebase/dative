define [
  'backbone'
  './field'
  './input-textarea-input'
], (Backbone, FieldView, InputTextareaInputView) ->

  # Utterance Judgement Field View
  # ------------------------------
  #
  # A field view specifically for a judgement <input> and an utterance
  # <textarea>. (Compare to the similar transcription-grammaticality-field
  # view.)

  class UtteranceJudgementFieldView extends FieldView

    getInputView: ->
      new InputTextareaInputView @context

    # `FieldView` will call this to set `@context` in the constructor.
    # The `InputTextareaInputView` instance needs to know how to label/valuate
    # its <input> and <textarea>.
    getContext: ->
      inputAttribute = 'judgement'
      defaultContext = super()
      _.extend(defaultContext,

        inputAttribute: inputAttribute
        inputName:      @getName inputAttribute
        inputClass:     @getClass inputAttribute
        inputTitle:     @getTooltip inputAttribute
        inputValue:     @getValue inputAttribute

        textareaName:   defaultContext.name
        textareaClass:  defaultContext.class
        textareaTitle:  defaultContext.title
        textareaValue:  defaultContext.value
      )

