define ['./resource'], (ResourceModel) ->

  # Subcorpus Model
  # ---------------
  #
  # A Backbone model for Dative subcorpora, i.e., OLD corpora.
  #
  # At present Dative `SubcorpusModel`s represent OLD corpora and have no
  # equivalent in the FieldDB data structure. They are called "subcorpora"
  # because the term "corpora" is used for FieldDB corpora, which are different.

  class SubcorpusModel extends ResourceModel

    resourceName: 'subcorpus'

    # When requesting from the OLD, we need to request 'corpora', not
    # 'subcorpora', hence this attribute.
    serverSideResourceName: 'corpora'

    editableAttributes: [
      'name'
      'description'
      'content'
      'tags'
      'form_search'
    ]

    manyToOneAttributes: ['form_search']

    manyToManyAttributes: ['tags']

    getValidator: (attribute) ->
      switch attribute
        when 'name' then @requiredString
        else null

    ############################################################################
    # Subcorpus Schema
    ############################################################################

    # See:
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/lib/schemata.py#L1091-L1111
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/corpus.py#L82-L104
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/model.py

    defaults: ->
      name: ''              # required, unique among corpus names, max 255 chars
      description: ''       # string description
      content: ''           # string containing form references
      tags: []              # OLD sends this as an array of objects
                            # (attributes: `id`, `name`) but receives it as an
                            # array of integer relational ids, all of which must
                            # be valid tag ids.
      form_search: null     # OLD sends this as an object (attributes: `id`,
                            # `name`) but receives it as a relational integer
                            # id; must be a valid form search id.

      # Attributes that the OLD sends to us, but which the OLD will ignore if
      # we try to send them back.
      id: null              # An integer relational id
      UUID: ''              # A string UUID
      enterer: null         # an object (attributes: `id`, `first_name`,
                            # `last_name`, `role`)
      modifier: null        # an object (attributes: `id`, `first_name`,
                            # `last_name`, `role`)
      datetime_entered: ""  # <string>  (datetime subcorpus was created/entered;
                            # generated on the server as a UTC datetime;
                            # communicated in JSON as a UTC ISO 8601 datetime,
                            # e.g., '2015-02-11T10:50:57.821192'.)
      datetime_modified: "" # <string>  (datetime subcorpus was last modified;
                            # format and construction same as
                            # `datetime_entered`.)
      files: []             # an array of objects (attributes: `id`, `name`,
                            # `filename`, `MIME_type`, `size`, `url`,
                            # `lossy_filename`)

    # OLD corpora are searched by issuing a SEARCH request against
    # /corpora/searchcorpora
    getSearchURL: -> "#{@getOLDURL()}/corpora/searchcorpora"

    # Getting the data needed to perform a search across OLD corpora requires
    # issuing a GET request to /corpora/new_search_corpora
    getNewSearchDataURL: -> "#{@getOLDURL()}/corpora/new_search_corpora"

