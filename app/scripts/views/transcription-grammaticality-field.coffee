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

