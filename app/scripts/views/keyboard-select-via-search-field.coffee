define [
  './resource-select-via-search-field'
  './keyboard-select-via-search-input'
], (ResourceSelectViaSearchFieldView, KeyboardSelectViaSearchInputView) ->

  class KeyboardSelectViaSearchFieldView extends ResourceSelectViaSearchFieldView

    getInputView: ->
      new KeyboardSelectViaSearchInputView @context

