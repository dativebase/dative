define ['./select-field'], (SelectFieldView) ->

  # Source Select(menu) Field View
  # ------------------------------
  #
  # A specialized SelectFieldView for OLD source objects, i.e,. texts such
  # as Uhlenbeck (1917). The only modification of the base class is that a
  # `selectTextGenerator` is supplied, i.e., a function that takes a person
  # object and returns a string to go between <option> and </option>.

  class PersonSelectFieldView extends SelectFieldView

    initialize: (options) ->
      options.selectTextGenerator = (option) ->
        "#{option.author} (#{option.year})"
      super

