define ['./resource'], (ResourceModel) ->

  # Tag Model
  # ---------
  #
  # A Backbone model for Dative tags.

  class TagModel extends ResourceModel

    resourceName: 'tag'

    ############################################################################
    # Tag Schema
    ############################################################################

    defaults: ->
      name: ''                                   # <string> Required, unique
                                                 # among tag
                                                 # names, max 255 chars.
      description: ''                            # <string> description of the
                                                 # tag.
      id: null                                   # <int> relational id
      datetime_modified: ""                      # <string>  (datetime resource
                                                 # was last modified; format
                                                 # and construction same as
                                                 # `datetime_entered`.)

    editableAttributes: [
      'name'
      'description'
    ]

    getValidator: (attribute) ->
      switch attribute
        when 'name' then @requiredString
        else null

