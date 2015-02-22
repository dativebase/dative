define [
  './field'
  './multiselect-input'
], (FieldView, MultiselectInputView) ->

  # Multiselect Field View
  # ----------------------
  #
  # A view for a data input field that is a <select> text] which is
  # jQueryUI-multiSelect-ified.

  class MultiselectFieldView extends FieldView

    getInputView: ->
      new MultiselectInputView @context

    initialize: (options) ->
      @width = options.width or '98.5%' # TODO: is this used?
      @selectValueAttribute = options.selectValueAttribute or 'id'
      @selectTextGenerator = options.selectTextGenerator or (o) -> o.name
      @sortByAttribute = options.sortByAttribute or 'name'

      # `@context.options` is expected to be an object. `optionsAttribute`
      # should be a key of that object that returns an array to be used as
      # options for building the multi-<select>.
      @optionsAttribute = options.optionsAttribute or options.attribute

      super

    getContext: ->
      _.extend(super,
        width: @width
        optionsAttribute: @optionsAttribute
        selectValueAttribute: @selectValueAttribute
        selectTextGenerator: @selectTextGenerator
        sortByAttribute: @sortByAttribute
      )

