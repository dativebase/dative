define ['./person-select-field'], (PersonSelectFieldView) ->

  # User Select(menu) Field View
  # ------------------------------
  #
  # A specialized PersonSelectFieldView for OLD user objects, e.g., verifier,
  # elicitor, etc. The only difference is that it supplies an
  # `optionsAttribute`, i.e., a string key specifying how to get the list
  # of user objects from `@options` in the template.

  class UserSelectFieldView extends PersonSelectFieldView

    initialize: (options) ->
      options.optionsAttribute = 'users'
      super

