define [
  'backbone'
  './input-set'
  './select-textarea-button-input'
], (Backbone, InputSetView, SelectTextareaButtonInputView) ->

  # Translations Input Set View
  # ---------------------------
  #
  # A view for a *set* of input field sets for modifying an array of translation
  # objects. That is, something like:
  #
  #   [
  #     {
  #       transcription: 'dog',
  #       grammaticality: ''
  #     },
  #     {
  #       transcription: 'wolf',
  #       grammaticality: '*'
  #     }
  #   ]
  #
  # The value of `@context.value` (where @context is the object passed to the
  # constructor) is an array like that shown above. Each object in the value
  # array gets its own input view: a `SelectTextareaButtonInputView` instance.
  #
  # When the <button> of one of the rendered input sub-views is clicked, this
  # view is responsible for removing the sub-view or adding a new one, as
  # appropriate. Most of this logic is declared in the base class
  # `InputSetView`.

  class TranslationsInputSetView extends InputSetView

    initialize: (@context) ->
      @selectAttribute = @context.translationSelectAttribute
      @textareaAttribute = @context.translationTextareaAttribute
      super

    # Override `InputSetView`'s default with a translation-appropriate input
    # view.
    getInputView: (inputContext) ->
      new SelectTextareaButtonInputView inputContext

    # Override `InputSetView`'s default with a translation-appropriate empty
    # object.
    getDefaultObject: ->
      defaultTranslationObject = {}
      defaultTranslationObject[@context.translationSelectAttribute] = ''
      defaultTranslationObject[@context.translationTextareaAttribute] = ''
      defaultTranslationObject

    # Override `InputSetView`'s default with a translation-appropriate context
    # attributes for the appropriateness <select> and the
    # translation-transcription <textarea>.
    getInputContext: (index, object) ->
      _.extend(super,
        selectAttribute:   @selectAttribute
        selectName:        @getArrayItemAttributeName @attribute, index, @selectAttribute
        selectClass:       @getClass @selectAttribute
        selectTitle:       @getTooltip "#{@attribute}.#{@selectAttribute}"
        selectValue:       object[@selectAttribute]

        textareaAttribute: @textareaAttribute
        textareaName:      @getArrayItemAttributeName @attribute, index, @textareaAttribute
        textareaClass:     @getClass @textareaAttribute
        textareaTitle:     @getTooltip "#{@attribute}.#{@textareaAttribute}"
        textareaValue:     object[@textareaAttribute]
      )

    # `InputSet`'s `getValueFromDOM` does most of the work. We pass the
    # textarea attribute (e.g., `"transcription"`) as the required attribute
    # parameter so that only inputs with transcriptions are added to the
    # resulting value array.
    getValueFromDOM: ->
      super @textareaAttribute

