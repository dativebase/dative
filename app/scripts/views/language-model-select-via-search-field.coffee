define [
  './resource-select-via-search-field'
  './language-model-select-via-search-input'
], (ResourceSelectViaSearchFieldView, LanguageModelSelectViaSearchInputView) ->

  class LanguageModelSelectViaSearchFieldView extends ResourceSelectViaSearchFieldView

    getInputView: ->
      new LanguageModelSelectViaSearchInputView @context

