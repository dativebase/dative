define [
  './relational-select-field-with-add-button'
  './../models/user-old'
  './../collections/users'
  './../utils/globals'
], (RelationalSelectFieldWithAddButtonView, UserModel,
  UsersCollection, globals) ->

  # Syntactic Category Relational Select(menu) Field, with Add Button, View
  # -----------------------------------------------------------------------
  #
  # For selecting from a list of syntactic categories. With "+" button for
  # creating new ones.

  class UserSelectFieldWithAddButtonView extends RelationalSelectFieldWithAddButtonView

    resourceName: 'user'
    resourcesCollectionClass: UsersCollection
    resourceModelClass: UserModel

    # Note: subclasses must valuate @attributeName with something like
    # 'elicitor'
    attributeName: 'user'

    initialize: (options) ->
      options.optionsAttribute = 'users'
      options.selectTextGetter = (option) ->
        "#{option.first_name} #{option.last_name}"
      super options

