define ['./resource'], (ResourceModel) ->

  # Phonology Model
  # ---------------
  #
  # A Backbone model for Dative phonologies.

  class PhonologyModel extends ResourceModel

    resourceName: 'phonology'

    ############################################################################
    # Phonology Schema
    ############################################################################

    # See:
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/phonology.py#L50-L64
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/controllers/phonologies.py
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/lib/schemata.py#L1041-L1049

    defaults: ->
      name: ''                 # required, unique among phonology names, max
                               # 255 chars
      description: ''          #
      script: ''               # The FST script of the phonology.

      # Attributes that the OLD sends to us, but which the OLD will ignore if
      # we try to send them back.
      id: null                 # An integer relational id
      UUID: ''                 # A string UUID
      enterer: null            # an object (attributes: `id`, `first_name`,
                               # `last_name`, `role`)
      modifier: null           # an object (attributes: `id`, `first_name`,
                               # `last_name`, `role`)
      datetime_entered: ""     # <string>  (datetime resource was created/entered;
                               # generated on the server as a UTC datetime;
                               # communicated in JSON as a UTC ISO 8601 datetime,
                               # e.g., '2015-02-11T10:50:57.821192'.)
      datetime_modified: ""    # <string>  (datetime resource was last modified;
                               # format and construction same as
                               # `datetime_entered`.)
      compile_succeeded: false
      compile_message: ''
      compile_attempt: ''      # A UUID

    editableAttributes: [
      'name'
      'description'
      'script'
    ]

