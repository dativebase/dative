define [
  './resource-select-via-search-field'
  './morphology-select-via-search-input'
], (ResourceSelectViaSearchFieldView, MorphologySelectViaSearchInputView) ->

  class MorphologySelectViaSearchFieldView extends ResourceSelectViaSearchFieldView

    getInputView: ->
      new MorphologySelectViaSearchInputView @context

