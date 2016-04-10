define ['./resource'], (ResourceModel) ->

  # Keyboard Model
  # --------------
  #
  # A Backbone model for Dative keyboards.

  class KeyboardModel extends ResourceModel

    resourceName: 'keyboard'

    ############################################################################
    # Keyboard Schema
    ############################################################################

    defaults: ->
      name: ''                    # <string> Required, unique
                                  # among keyboard
                                  # names, max 255 chars.
      description: ''             # <string> description of the
                                  # keyboard.
      keyboard: {}                # <object> maps JavaScript key
                                  # codes to Unicode
                                  # characters/strings.
      id: null                    # <int> relational id
      datetime_entered: ""        # <string>  (datetime resource
                                  # was last entered; generated
                                  # on the server as a UTC
                                  # datetime; communicated in
                                  # JSON as a UTC ISO 8601
                                  # datetime, e.g.,
                                  # '2015-02-11T10:50:57.821192'.)
      datetime_modified: ""       # <string>  (datetime resource
                                  # was last modified; format
                                  # and construction same as
                                  # `datetime_entered`.)
      enterer: null               # <object>  (enterer of the keyboard.)
      modifier: null              # <object>  (last user to modify the keyboard.)

    editableAttributes: [
      'name'
      'description'
      'keyboard'
    ]

    getValidator: (attribute) ->
      switch attribute
        when 'name' then @requiredString
        else null

