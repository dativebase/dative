define ['./resource'], (ResourceModel) ->

  # Syntactic Category Model
  # ------------------------
  #
  # A Backbone model for Dative syntactic categories.

  class SyntacticCategoryModel extends ResourceModel

    resourceName: 'syntacticCategory'

    ############################################################################
    # Syntactic Category Schema
    ############################################################################

    defaults: ->
      name: ''                                   # <string> Required, unique
                                                 # among syntactic category
                                                 # names, max 255 chars.
      type: ''                                   # According to the OLD, this
                                                 # should be one of the
                                                 # following values: 'lexical',
                                                 # 'phrasal' or 'sentential'.
      description: ''                            # <string> description of the
                                                 # syntactic category.
      id: null                                   # <int> relational id
      datetime_modified: ""                      # <string>  (datetime resource
                                                 # was last modified; format
                                                 # and construction same as
                                                 # `datetime_entered`.)

    editableAttributes: [
      'name'
      'type'
      'description'
    ]

    getValidator: (attribute) ->
      switch attribute
        when 'name' then @requiredString
        else null


