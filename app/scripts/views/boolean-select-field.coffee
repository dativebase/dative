define [
  './select-field'
], (SelectFieldView) ->

  # Boolean Select Field
  # --------------------
  #
  # For selecting `true` or `false`. Perhaps better to use a different type of
  # control than a selectmenu here, but it works for now.
  #
  # .. warning::
  #
  #   Any `ResourceAddWidgetView` that uses this needs to modify its
  #   `storeOptionsDataGlobally` method so that the `data` object contains an
  #   attribute `booleans` which returns the array `[true, false]`. E.g.,::
  #
  #       storeOptionsDataGlobally: (data) ->
  #         if @model.get('id') # The GET /<resources>/<id>/edit case
  #           data.data.booleans = [true, false]
  #         else
  #           data.booleans = [true, false]
  #         super data

  class BooleanSelectFieldView extends SelectFieldView

    initialize: (options) ->
      options.optionsAttribute = 'booleans'
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) -> o
      options.required = true
      super options

