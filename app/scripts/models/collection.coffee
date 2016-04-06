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
    #
    # Note: the OLD also returns `contents_unpacked`. This is a version of the
    # `contents` value where all collection-embedding directives are replaced
    # by the `contents` value of the referenced collection. Dative may at some
    # point need to make use of this `contents_unpacked` value.

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
      speaker: null           # A reference to the OLD speaker with whom this
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

    manyToOneAttributes: ['source', 'elicitor', 'speaker']

    manyToManyAttributes: ['files', 'tags']

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

    # The collection model overrides the resource model's `fetchResource`
    # method so that it can pass GET params in the request. This is necessary
    # because it allows us to request a LaTeX representation of the
    # collection's contents from the server.
    fetchResource: (id, payload=null) ->
      @trigger "fetch#{@resourceNameCapitalized}Start"
      @constructor.cors.request(
        method: 'GET'
        url: @getFetchResourceURL id, payload
        onload: (responseJSON, xhr) =>
          @fetchResourceOnloadHandler responseJSON, xhr
        onerror: (responseJSON) =>
          @trigger "fetch#{@resourceNameCapitalized}End"
          error = responseJSON.error or 'No error message provided.'
          @trigger "fetch#{@resourceNameCapitalized}Fail", error, @
          console.log "Error in GET request to
            /#{@getServerSideResourceName()}/#{@get 'id'} (onerror triggered)."
      )

    # Add `payload` to the URL as a GET query string.
    getFetchResourceURL: (id, payload=null) ->
      if payload
        params = ("#{k}=#{v}" for k, v of payload).join '&'
        "#{@getOLDURL()}/#{@getServerSideResourceName()}/#{id}?#{params}"
      else
        "#{@getOLDURL()}/#{@getServerSideResourceName()}/#{id}"

