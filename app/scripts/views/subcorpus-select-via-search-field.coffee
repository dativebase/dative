define [
  './resource-select-via-search-field'
  './subcorpus-select-via-search-input'
], (ResourceSelectViaSearchFieldView, SubcorpusSelectViaSearchInputView) ->

  class SubcorpusSelectViaSearchFieldView extends ResourceSelectViaSearchFieldView

    getInputView: ->
      new SubcorpusSelectViaSearchInputView @context


