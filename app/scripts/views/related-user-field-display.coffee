define [
  './related-resource-field-display'
  './user-old'
  './../models/user-old'
  './../collections/users'
], (RelatedResourceFieldDisplayView, UserView, UserModel, UsersCollection) ->

  # Related User Field Display View
  # -------------------------------
  #
  # For displaying a user as a field/attribute of another resource, such that
  # the user is displayed as a link that, when clicked, causes the resource to
  # be displayed in a dialog box.

  class RelatedUserFieldDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'user'
    resourceModelClass: UserModel
    resourcesCollectionClass: UsersCollection
    resourceViewClass: UserView

    resourceAsString: (resource) ->
      try
        firstName = resource.first_name or ''
        lastName = resource.last_name or ''
        "#{firstName} #{lastName}".trim()
      catch
        ''

