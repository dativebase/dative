define [
  './resources'
  './../models/user-old'
], (ResourcesCollection, UserModel) ->

  # Users Collection
  # -----------------------
  #
  # Holds models for users.

  class UsersCollection extends ResourcesCollection

    resourceName: 'user'
    model: UserModel


