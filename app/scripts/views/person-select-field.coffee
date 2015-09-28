define [
  './relational-select-field'
], (RelationalSelectFieldView) ->

  # Person Select(menu) Field View
  # ------------------------------
  #
  # A specialized RelationalSelectFieldView for OLD people objects, e.g.,
  # speaker, elicitor, etc. The only difference is that it supplies a
  # `selectTextGetter`, i.e., a function that takes a person object and
  # returns a string to go between <option> and </option>.

  class PersonSelectFieldView extends RelationalSelectFieldView

    initialize: (options) ->
      options.selectTextGetter = (option) ->
        "#{option.first_name} #{option.last_name}"
      super

