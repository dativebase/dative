define [
  './resource-select-via-search-field'
  './morphological-parser-select-via-search-input'
], (ResourceSelectViaSearchFieldView, MorphologicalParserSelectViaSearchInputView) ->

  class MorphologicalParserSelectViaSearchFieldView extends ResourceSelectViaSearchFieldView

    getInputView: ->
      new MorphologicalParserSelectViaSearchInputView @context

