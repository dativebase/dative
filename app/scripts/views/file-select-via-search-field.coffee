define [
  './resource-select-via-search-field'
  './file-select-via-search-input'
], (ResourceSelectViaSearchFieldView, FileSelectViaSearchInputView,
  ResourceAsRowView, SourceModel) ->


  class FileSelectViaSearchFieldView extends ResourceSelectViaSearchFieldView

    getInputView: ->
      new FileSelectViaSearchInputView @context

    listenToEvents: ->
      super
      if @inputView
        @listenTo @inputView, 'validateMe', @myValidate

    myValidate: ->
      if @submitAttempted then @validate()


