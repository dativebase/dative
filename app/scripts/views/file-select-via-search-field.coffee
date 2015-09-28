define [
  './resource-select-via-search-field'
  './file-select-via-search-input'
], (ResourceSelectViaSearchFieldView, FileSelectViaSearchInputView,
  ResourceAsRowView, SourceModel) ->


  class FileSelectViaSearchFieldView extends ResourceSelectViaSearchFieldView

    getInputView: ->
      new FileSelectViaSearchInputView @context

