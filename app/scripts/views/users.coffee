define [
  './resources'
  './user-old'
  './../collections/users'
  './../models/user-old'
  './../utils/globals'
], (ResourcesView, UserView, UsersCollection, UserModel, globals) ->

  # Users View
  # -----------------
  #
  # Displays a collection of users for browsing, with pagination. Also
  # contains a model-less UserView instance for creating new users
  # within the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class UsersView extends ResourcesView

    resourceName: 'user'
    resourceView: UserView
    resourcesCollection: UsersCollection
    resourceModel: UserModel

    getCanCreateNew: ->
      try
        globals.applicationSettings.get('loggedInUser').role is 'administrator'
      catch
        false

