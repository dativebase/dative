define [
  './resource-select-via-search-field'
  './resources-select-via-search-input'
], (ResourceSelectViaSearchFieldView, ResourcesSelectViaSearchInputView) ->

  # Resources Select Via Search Field View
  # --------------------------------------
  #
  # A view for selecting *zero or more of* a particular resource (say, for a
  # many-to-many relation) by searching for them in a search input. This input
  # does some "smart" search: it interprets a string of digits as an id and
  # anything else as a space-delimited set of conjunctive search terms over a
  # specified set # of attribute values. See
  # `ResourcesSelectViaSearchInputView`.

  class ResourcesSelectViaSearchFieldView extends ResourceSelectViaSearchFieldView

    getInputView: ->
      new ResourcesSelectViaSearchInputView @context


