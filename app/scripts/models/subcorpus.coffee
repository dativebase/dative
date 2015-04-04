define [
    './../utils/globals'
    './base'
  ], (globals, BaseModel) ->

  # Subcorpus Model
  # ---------------
  #
  # A Backbone model for Dative subcorpora, i.e., OLD corpora.
  #
  # At present Dative `SubcorpusModel`s represent OLD corpora and have no
  # equivalent in the FieldDB data structure. They are called "subcorpora"
  # because the term "corpora" is used for FieldDB corpora, which are different.

  class SubcorpusModel extends BaseModel

    initialize: (options) ->
      if options?.collection then @collection = options.collection
      @activeServerType = @getActiveServerType()
      super options

    url: 'fakeurl' # Backbone throws 'A "url" property or function must be
                   # specified' if this is not present.

    getActiveServerType: ->
      globals.applicationSettings.get('activeServer').get 'type'

    validate: (attributes, options) ->
      attributes = attributes or @attributes
      errors = {}
      for attribute, value of attributes
        attributeValidator = @getValidator attribute
        if attributeValidator
          error = attributeValidator.apply @, [value]
          if error then errors[attribute] = error
      if _.isEmpty errors then undefined else errors

    getValidator: (attribute) ->
      switch attribute
        when 'name' then @requiredString
        else null

    # This is an example validator for later modification...
    # TODO: delete this method ...
    validTitle: (value) ->
      error = null
      if (t for t in value when t.transcription.trim()).length is 0
        error = 'Please enter one or more translations'
      error

    manyToOneAttributes: ['form_search']

    manyToManyAttributes: ['tags']

    # Return a representation of the model's state that the OLD likes: i.e.,
    # with relational values as ids or arrays thereof.
    toOLD: ->
      result = _.clone @attributes
      # Not doing this causes a `RangeError: Maximum call stack size exceeded`
      # when cors.coffee tries to call `JSON.stringify` on a subcorpus model that
      # contains a subcorpora collection that contains that same subcorpus model,
      # etc. ad infinitum.
      delete result.collection
      for attribute in @manyToOneAttributes
        result[attribute] = result[attribute]?.id or null
      for attribute in @manyToManyAttributes
        result[attribute] = (v.id for v in result[attribute] or [])
      result

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

    # Returns `true` if the model is empty.
    isEmpty: ->
      attributes = _.clone @attributes
      delete attributes.collection
      _.isEqual @defaults(), attributes

    getOLDURL: -> globals.applicationSettings.get('activeServer').get 'url'

    # Issue a GET request to /corpora/new on the active OLD server.
    # This returns a JSON object containing the data necessary to
    # create a new OLD corpus, an object with a subset of the following keys:
    # `form_searches`, `users`, `tags`, and `corpus_formats`. See:
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/controllers/corpora.py#L174
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/controllers/corpora.py#L740-L754
    # Note: `corpus_formats` is a dict (object) with attributes `treebank` and `transcriptions only`. See
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/lib/utils.py#L1428-L1439
    getNewSubcorpusData: ->
      Backbone.trigger 'getNewSubcorpusDataStart'
      SubcorpusModel.cors.request(
        method: 'GET'
        url: "#{@getOLDURL()}/corpora/new"
        onload: (responseJSON) =>
          Backbone.trigger 'getNewSubcorpusDataEnd'
          Backbone.trigger 'getNewSubcorpusDataSuccess', responseJSON
          # TODO: trigger FAIL event if appropriate (how do we know?)
          # We know because the `xhr.status` will not be 200.
          # Backbone.trigger 'getNewSubcorpusDataFail',
          #     "Failed in fetching the data."
        onerror: (responseJSON) =>
          Backbone.trigger 'getNewSubcorpusDataEnd'
          Backbone.trigger 'getNewSubcorpusDataFail',
            'Error in GET request to OLD server for /corpora/new'
          console.log 'Error in GET request to OLD server for /corpora/new'
      )

    # Destroy an OLD corpus.
    # DELETE `<OLD_URL>/corpora/<corpus.id>`
    destroySubcorpus: (options) ->
      Backbone.trigger 'destroySubcorpusStart'
      SubcorpusModel.cors.request(
        method: 'DELETE'
        url: "#{@getOLDURL()}/corpora/#{@get 'id'}"
        onload: (responseJSON, xhr) =>
          Backbone.trigger 'destroySubcorpusEnd'
          if xhr.status is 200
            Backbone.trigger 'destroySubcorpusSuccess', @
          else
            error = responseJSON.error or 'No error message provided.'
            Backbone.trigger 'destroySubcorpusFail', error
            console.log "DELETE request to /corpora/#{@get 'id'}
              failed (status not 200)."
            console.log error
        onerror: (responseJSON) =>
          Backbone.trigger 'destroySubcorpusEnd'
          error = responseJSON.error or 'No error message provided.'
          Backbone.trigger 'destroySubcorpusFail', error
          console.log "Error in DELETE request to /corpora/#{@get 'id'}
            (onerror triggered)."
      )

