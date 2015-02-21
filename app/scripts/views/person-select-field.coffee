define ['./select-field'], (SelectFieldView) ->

  # Person Select(menu) Field View
  # ------------------------------
  #
  # A specialized SelectFieldView for OLD people objects, e.g., speaker,
  # elicitor, etc. The only difference is that it supplies a
  # `selectTextGenerator`, i.e., a function that takes a person object and
  # returns a string to go between <option> and </option>.

  class PersonSelectFieldView extends SelectFieldView

    initialize: (options) ->
      options.selectTextGenerator = (option) ->
        "#{option.first_name} #{option.last_name}"
      super

