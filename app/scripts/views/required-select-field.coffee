define ['./select-field'], (SelectFieldView) ->

  # Required Select(menu) Field View
  # --------------------------------
  #
  # A select field where one choice must be selected, i.e., no empty option.

  class RequiredSelectFieldView extends SelectFieldView

    initialize: (options) ->
      options.required = true
      super

