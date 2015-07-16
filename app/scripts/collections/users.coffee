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

    # This recognizes an OLD "username-already-taken" error message and returns
    # 'username'.
    getAttributeForError: (error) ->
      regex = /^The (\w+) \w+ is already taken\.$/
      if regex.test error
        'username'
      else
        null

