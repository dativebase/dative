define [
  './resource-select-via-search-field'
  './search-select-via-search-input'
], (ResourceSelectViaSearchFieldView, SearchSelectViaSearchInputView) ->

  class SearchSelectViaSearchFieldView extends ResourceSelectViaSearchFieldView

    getInputView: ->
      new SearchSelectViaSearchInputView @context


