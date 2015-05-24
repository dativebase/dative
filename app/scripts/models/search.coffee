define ['./resource'], (ResourceModel) ->

  # Search Model
  # ---------------
  #
  # A Backbone model for Dative searches.

  class SearchModel extends ResourceModel

    resourceName: 'search'

    serverSideResourceName: 'formsearches'


    editableAttributes: [
      'name'
      'description'
      'search'
    ]

    manyToOneAttributes: []

    manyToManyAttributes: []

    getValidator: (attribute) ->
      switch attribute
        when 'name' then @requiredString
        else null

    ############################################################################
    # Search Schema
    ############################################################################

    # See:
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/lib/schemata.py#L846-L854
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/formsearch.py
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/model.py

    defaults: ->
      name: ''              # required, unique among search names, max 255 chars
      description: ''       # string description
      search: []            # an OLD form search (an array)

      # Attributes that the OLD sends to us, but which the OLD will ignore if
      # we try to send them back.
      id: null              # An integer relational id
      enterer: null         # an object (attributes: `id`, `first_name`,
                            # `last_name`, `role`)
      datetime_modified: "" # <string>  (datetime search was last modified;
                            # format and construction same as
                            # `datetime_entered`.)


