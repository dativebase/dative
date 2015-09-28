define ['./resource'], (ResourceModel) ->

  # Orthography Model
  # ---------
  #
  # A Backbone model for Dative orthographies.

  class OrthographyModel extends ResourceModel

    resourceName: 'orthography'

    ############################################################################
    # Orthography Schema
    ############################################################################

    defaults: ->
      id: null                    # <int> relational id
      name: ''                    # <string> Required, unique among orthography
                                  # names, max 255 chars.
      orthography: ''             # = Column(UnicodeText)
      lowercase: false            # ...
      initial_glottal_stops: true # ...
      datetime_modified: ""       # <string>  (datetime resource was last
                                  # modified; format and construction same as
                                  # `datetime_entered`.)

    editableAttributes: [
      'name'
      'orthography'
      'lowercase'
      'initial_glottal_stops'
    ]

    getValidator: (attribute) ->
      switch attribute
        when 'name' then @requiredString
        when 'orthography' then @requiredString
        else null


