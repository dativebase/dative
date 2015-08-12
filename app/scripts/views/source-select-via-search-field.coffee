define [
  './resource-select-via-search-field'
  './source-select-via-search-input'
], (ResourceSelectViaSearchFieldView, SourceSelectViaSearchInputView) ->

  class SourceSelectViaSearchFieldView extends ResourceSelectViaSearchFieldView

    getInputView: ->
      new SourceSelectViaSearchInputView @context

