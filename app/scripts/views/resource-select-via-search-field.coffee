define [
  './field'
  './resource-select-via-search-input'
], (FieldView, ResourceSelectViaSearchInputView) ->

  # Resource Select Via Search Field View
  # -------------------------------------
  #
  # A view for selecting a particular resource (say, for a many-to-one
  # relation) by searching for it in a search input. This input should do some
  # "smart" search, i.e., try to understand what the user may be searching for.

  class ResourceSelectViaSearchFieldView extends FieldView

    getInputView: ->
      new ResourceSelectViaSearchInputView @context

