define [
  './resources-select-via-search-field'
  './files-select-via-search-input'
], (ResourcesSelectViaSearchFieldView, FilesSelectViaSearchInputView) ->


  class FilesSelectViaSearchFieldView extends ResourcesSelectViaSearchFieldView

    getInputView: ->
      new FilesSelectViaSearchInputView @context

