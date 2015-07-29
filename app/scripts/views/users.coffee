define [
  './resources'
  './user-old-circular'
  './../collections/users'
  './../models/user-old'
  './../utils/globals'
], (ResourcesView, UserViewCircular, UsersCollection, UserModel, globals) ->

  # Users View
  # -----------------
  #
  # Displays a collection of users for browsing, with pagination. Also
  # contains a model-less UserView instance for creating new users
  # within the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.
  #
  # Note: we use `UserViewCircular`: this is the one that can embed forms and
  # files in the HTML representations of the users. Since it imports FormView
  # and FileView, it is not used to represent the relational attributes of the
  # models of those views.

  class UsersView extends ResourcesView

    resourceName: 'user'
    resourceView: UserViewCircular
    resourcesCollection: UsersCollection
    resourceModel: UserModel

    getCanCreateNew: ->
      try
        globals.applicationSettings.get('loggedInUser').role is 'administrator'
      catch
        false

