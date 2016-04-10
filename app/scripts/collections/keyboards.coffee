define [
  './resources'
  './../models/keyboard'
], (ResourcesCollection, KeyboardModel) ->

  # Keyboards Collection
  # --------------------
  #
  # Holds models for keyboards.

  class KeyboardsCollection extends ResourcesCollection

    resourceName: 'keyboard'
    model: KeyboardModel

    # Return a representation of `resource` that the server will accept (for a
    # create or update request). See `collections/forms.coffee for a
    # FieldDB-specific override.
    getResourceForServer: (resource) ->
      result = resource.toOLD()
      result.keyboard = @prepKeyboard result.keyboard
      result

    prepKeyboard: (keyboard) ->
      keysToDelete = []
      for keycode, keyMap of keyboard
        if not _.some(_.values(keyMap))
          keysToDelete.push keycode
      for attr in keysToDelete
        delete keyboard[attr]
      JSON.stringify keyboard

