define [
  './field'
  './select-input'
], (FieldView, SelectInputView) ->

  # Select(menu) Field View
  # -----------------------
  #
  # A view for a data input field that is a <select> (with a label and
  # validation machinery, as inherited from FieldView) and which is transformed
  # into a jQuery selectmenu.

  class SelectFieldView extends FieldView

    initialize: (options) ->
      @required = options.required or false
      @width = options.width or '98.5%'
      @selectValueAttribute = options.selectValueAttribute or 'id'
      @selectTextGenerator = options.selectTextGenerator or (o) -> o.name

      # `@context.options` is expected to be an object. `optionsAttribute`
      # should be a key of that object that returns an array to be used as
      # options for building the <select>.
      @optionsAttribute = options.optionsAttribute or @utils.pluralize options.attribute

      super

    getInputView: ->
      new SelectInputView @context

    getContext: ->
      _.extend(super,
        required: @required
        width: @width
        optionsAttribute: @optionsAttribute
        selectValueAttribute: @selectValueAttribute
        selectTextGenerator: @selectTextGenerator
      )

