define [
  './field'
  './search-input'
], (FieldView, SearchInputView) ->

  # Search Field View
  # -------------------
  #
  # A view for a data input field that is a search, i.e., a JSON object
  # encoding a search expression using the OLD search format.

  class SearchFieldView extends FieldView

    getInputView: ->
      new SearchInputView @context

