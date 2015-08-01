define ['./resource'], (ResourceModel) ->

  # Collection Model
  # ----------------
  #
  # A Backbone model for Dative collections, i.e., the text-like objects of the
  # OLD.

  class CollectionModel extends ResourceModel

    resourceName: 'collection'

    ############################################################################
    # Collection Schema
    ############################################################################

    defaults: ->
      title: ''               # <string> Required, unique among collection
                              # names, max 255 chars.
      description: ''         # <string> description of the collection.
      type: ''                # <string> max 255 chars.
      url: ''                 # <string> max 255 chars.
      markup_language: ''     # One of "Markdown" or "reStructuredText",
                              # defaults to "reStructuredText".
      contents: ''            # a string of lightweight markup that also
                              # contains references to forms. This defines the
                              # collection.
      html: ''                # HTML generated from the user-supplied markup.
      source: null            # <object>  (textual source (e.g., research
                              # paper, book of texts, pedagogical material,
                              # etc.) of the collection, if applicable;
                              # received as an object, returned as an integer
                              # id.)
      speaker: null           # A reference to the OLD speaker with whome this
                              # collection was elicited, if appropriate.
      elicitor: null          # A reference to the OLD user who elicited this
                              # collection, if appropriate.
      date_elicited: ''       # When this collection was elicited, if appropriate.
      tags: []                # An array of tags assigned to the collection.
      files: []               # An array of files associated to this collection.
      enterer: null           # an object (attributes: `id`, `first_name`,
                              # `last_name`, `role`)
      modifier: null          # an object (attributes: `id`, `first_name`,
                              # `last_name`, `role`)
      datetime_entered: ""    # <string>  (datetime file was created/entered;
                              # generated on the server as a UTC datetime;
                              # communicated in JSON as a UTC ISO 8601 datetime,
                              # e.g., '2015-02-11T10:50:57.821192'.)
      datetime_modified: ""   # <string>  (datetime file was last modified;
                              # format and construction same as
                              # `datetime_entered`.)
      UUID: ''                # A string UUID
      id: null                # <int> relational id

    editableAttributes: [
      'title'
      'description'
      'type'
      'url'
      'markup_language'
      'contents'
      'source'
      'speaker'
      'elicitor'
      'date_elicited'
      'tags'
      'files'
    ]

    getValidator: (attribute) ->
      switch attribute
        when 'title' then @requiredString
        when 'url' then @urlFragment
        else null


    urlFragment: (value) ->
      if /^[a-zA-Z0-9_\/-]{0,255}$/.test value
        null
      else
        'Only a-z, A-Z, 0-9, _, /, and - are allowed in the url value.'


