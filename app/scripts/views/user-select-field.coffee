define [
  './relational-select-field'
], (RelationalSelectFieldView) ->

  # User Select(menu) Field View
  # ----------------------------
  #
  # A specialized RelationalSelectFieldView for OLD user objects, e.g.,
  # verifier, elicitor, etc. The only difference between this and the
  # `PersonSelectFieldView` is that this supplies an `optionsAttribute`, i.e.,
  # a string key specifying how to get the list of user objects from `@options`
  # in the template.

  class UserSelectFieldView extends RelationalSelectFieldView

    initialize: (options) ->
      options.optionsAttribute = 'users'
      options.selectTextGetter = (option) ->
        "#{option.first_name} #{option.last_name}"
      super options

