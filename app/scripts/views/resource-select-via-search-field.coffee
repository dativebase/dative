define [
  './field'
  './resource-select-via-search-input'
], (FieldView, ResourceSelectViaSearchInputView) ->

  # Resource Select Via Search Field View
  # -------------------------------------
  #
  # A view for selecting a particular resource (say, for a many-to-one
  # relation) by searching for it in a search input. This input does some
  # "smart" search: it interprets a string of digits as an id and anything else
  # as a space-delimited set of conjunctive search terms over a specified set
  # of attribute values. See `ResourceSelectViaSearchInputView`.

  class ResourceSelectViaSearchFieldView extends FieldView

    getInputView: ->
      new ResourceSelectViaSearchInputView @context

    listenToEvents: ->
      super
      if @inputView
        @listenTo @inputView, 'validateMe', @myValidate
      @listenTo @model, "change:#{@attribute}", @refresh

    myValidate: ->
      if @submitAttempted then @validate()

