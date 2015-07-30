define ['./resource'], (ResourceModel) ->

  # Elicitation Method Model
  # ------------------------
  #
  # A Backbone model for Dative elicitation methods.

  class ElicitationMethodModel extends ResourceModel

    resourceName: 'elicitationMethod'

    ############################################################################
    # Elicitation Method Schema
    ############################################################################

    defaults: ->
      name: ''                                   # <string> Required, unique
                                                 # among elicitation method
                                                 # names, max 255 chars.
      description: ''                            # <string> description of the
                                                 # elicitation method.
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

