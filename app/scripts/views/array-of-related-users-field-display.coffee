define [
  './array-of-related-resources-field-display'
  './user-old'
  './../models/user-old'
  './../collections/users'
], (ArrayOfRelatedResourcesFieldDisplayView, UserView, UserModel,
  UsersCollection) ->

  # Array of Related Users Field Display View
  # -----------------------------------------
  #
  # For displaying the users that are related to another resource. Each user is
  # represented by a link (whose text is the name) that triggers an opening of
  # the user in a dialog box.

  class ArrayOfRelatedUsersFieldDisplayView extends ArrayOfRelatedResourcesFieldDisplayView

    resourceName: 'user'
    attributeName: 'users'

    getContext: ->
      _.extend(super,
        subattribute: 'id'
        relatedResourceRepresentationViewClass:
          @relatedResourceRepresentationViewClass
        resourceName: @resourceName
        attributeName: @attributeName
        resourceModelClass: UserModel
        resourcesCollectionClass: UsersCollection
        resourceViewClass: UserView
        resourceAsString: @resourceAsString
        getRelatedResourceId: ->
          finder = {}
          finder[@subattribute] = @context.originalValue
          _.findWhere(@context.model.get(@attributeName), finder).id
      )

    # The string returned by this method will be the text of link that
    # represents each selected user.
    # NOTE: the repetitive logic here is for search match highlighting.
    resourceAsString: (resourceId) ->
      resource = _.findWhere(@model.get(@attributeName), {id: resourceId})
      "#{resource.first_name} #{resource.last_name}"

