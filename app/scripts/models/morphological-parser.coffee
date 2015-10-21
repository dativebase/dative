define [
  './resource'
  './../utils/globals'
], (ResourceModel, globals) ->

  # Morphological Parser Model
  # --------------------------
  #
  # A Backbone model for Dative morphological parsers.

  class MorphologicalParserModel extends ResourceModel

    resourceName: 'morphologicalParser'
    serverSideResourceName: 'morphologicalparsers'

    initialize: (attributes, options) ->
      super attributes, options
      @listenTo @, 'change:compile_attempt', @resetParseCache
      @parseCache = @fetchParseCache()

    # Each parser resource has a cache in localStorage whose key is a unique
    # string constructed from the web service's URL and the parser's last
    # compile_attempt value. Note that multiple `MorphologicalParserModel`
    # instances can exist in a Dative app and they will (should) all access and
    # modify the same localStorage cache, as needed.
    getLocalStorageKey: (previous=false) ->
      serverURL = globals.applicationSettings.get('activeServer').get 'url'
      if previous
        compileAttempt = @previousAttributes().compile_attempt
      else
        compileAttempt = @get 'compile_attempt'
      if compileAttempt
        "dative-#{serverURL}-morphological-parser-#{compileAttempt}-parse-cache"
      else
        null

    # Fetch our client-side-stored (in localStorage) cache of parse mappings.
    fetchParseCache: ->
      key = @getLocalStorageKey()
      if key
        localStorageCache = localStorage.getItem key
        if localStorageCache
          JSON.parse localStorageCache
        else
          localStorage.setItem key, JSON.stringify({})
          {}
      else
        console.log "WARN: unable to get persisted cache: this parser has no
          `compile_attempt` attribute"
        {}

    # Save the in-memory cache of parse results to localStorage.
    persistParseCache: ->
      key = @getLocalStorageKey()
      if key
        localStorage.setItem key, JSON.stringify(@parseCache)
      else
        console.log "WARN: unable to persist cache: this parser has no
          `compile_attempt` attribute"

    # We delete our old localStorage parse cache and create a new one when
    # our MorphologicalParserModel's `compile_attempt` attribute changes. This
    # attribute changing usually means that the parser will behave differently,
    # though that isn't necessarily true if the compile was made with no change
    # to the parser's phonology, morphology, or language model.
    # TODO: make this reset more sensitive to actual changes to the behaviour
    # of the parser model.
    resetParseCache: ->
      previousLocalStorageKey = @getLocalStorageKey true
      currentLocalStorageKey = @getLocalStorageKey()
      localStorage.removeItem previousLocalStorageKey
      @parseCache = {}
      @persistParseCache()

    # Cache our parse results from the server in memory and in localStorage.
    cacheParseResults: (parseResults) ->
      for input, output of parseResults
        @parseCache[input] = output
      @persistParseCache()

    # Request a parse for a word.
    # PUT `<URL>/morphologicalparsers/<id>/parse`
    # Note: we try to minimize requests to the server and to minimize how many
    # words are sent to the server for parsing on any necessary requests.
    parse: (words) ->
      wordsNeedingParse = (w for w in words when w not of @parseCache)
      if wordsNeedingParse.length > 0
        # We remember the words that we already have (cached) outputs for so we
        # can add them to the server's response on a successful request. See
        # the `parseOnloadHandler` below.
        @wordsCached = (w for w in words when w of @parseCache)
        @_parse wordsNeedingParse
      else
        # Client-side retrieval of cached parse results. Note we use the
        # same API, i.e., we trigger the same events that a successful request
        # to the server would.
        @trigger "parseStart"
        result = {}
        for word in words
          result[word] = @parseCache[word]
        @trigger "parseSuccess", result
        @trigger "parseEnd"

    # Request a parse for a word. This is the *real* parse method, the one that
    # issues a request to the server.
    # PUT `<URL>/morphologicalparsers/<id>/parse`
    _parse: (words) ->
      @trigger "parseStart"
      @constructor.cors.request(
        method: 'PUT'
        url: "#{@getOLDURL()}/morphologicalparsers/#{@get 'id'}/parse"
        payload: @getParsePayload words
        onload: (responseJSON, xhr) => @parseOnloadHandler responseJSON, xhr
        onerror: (responseJSON) =>
          @trigger "parseEnd"
          error = responseJSON.error or 'No error message provided.'
          @trigger "parseFail", error
          console.log "Error in PUT request to
            #{@getOLDURL()}/morphologicalparsers/#{@get 'id'}/parse
            (onerror triggered)."
      )

    # Input in body of HTTP request that morphological parser resources expect:
    # ``{'transcriptions': [t1, t2, ...]}``.
    getParsePayload: (words) ->
      if @utils.type(words) is 'string'
        words = words.split /\s+/
      {transcriptions: words}

    # Respond to a successful parse request to the server. Here we ...
    # 1. cache the results from the server
    # 2. add our cached response to the object passed to any 'parseSuccess'
    #    listeners.
    parseOnloadHandler: (responseJSON, xhr, directionCapitalized) ->
      @trigger "parseEnd"
      if xhr.status is 200
        @cacheParseResults responseJSON
        if @wordsCached and @wordsCached.length > 0
          for word in @wordsCached
            responseJSON[word] = @parseCache[word]
        @trigger "parseSuccess", responseJSON
      else
        error = responseJSON.error or 'No error message provided.'
        @trigger "parseFail", error
        console.log "PUT request to
          #{@getOLDURL()}/morphologicalparsers/#{@get 'id'}/parse
          failed (status not 200)."
        console.log error


    ############################################################################
    # morphological parser Schema
    ############################################################################

    # See:
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/lib/schemata.py#L1201-L1216
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/morphologicalparser.py#L145-L166
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/controllers/morphologicalparsers.py

    defaults: ->

      name: ''                    # <string>
      description: ''             # <string>
      phonology: null             # <int id>/<object> a phonology resource.
      morphology: null            # <int id>/<object> a morphology resource.
      language_model: null        # <int id>/<object> a language model resource.

      # Attributes that the OLD sends to us, but which the OLD will ignore if
      # we try to send them back.

      id: null                   # <int> relational id
      UUID: ''                   # <string> UUID
      enterer: null              # <object> attributes: `id`,
                                 # `first_name`, `last_name`,
                                 # `role`
      modifier: null             # <object> attributes: `id`,
                                 # `first_name`, `last_name`,
                                 # `role`
      datetime_entered: ""       # <string>  (datetime resource
                                 # was created/entered;
                                 # generated on the server as a
                                 # UTC datetime; communicated
                                 # in JSON as a UTC ISO 8601
                                 # datetime, e.g.,
                                 # '2015-02-11T10:50:57.821192'.)
      datetime_modified: ""      # <string>  (datetime resource
                                 # was last modified; format
                                 # and construction same as
                                 # `datetime_entered`.)
      generate_succeeded: false  # <boolean> will be true if server has
                                 # generated the parser.
      generate_message: ''       # <string> the message that the OLD returns
                                 # (indicating success or failure) after trying
                                 # to generate this parser.
      generate_attempt: ''       # <string> a UUID.
      compile_succeeded: false   # <boolean> will be true if server has
                                 # compiled the parser.
      compile_message: ''        # <string> the message that the OLD returns
                                 # (indicating success or failure) after trying
                                 # to compile this parser.
      compile_attempt: ''        # <string> a UUID.

    editableAttributes: [
      'name'
      'description'
      'phonology'
      'morphology'
      'language_model'
    ]

    getValidator: (attribute) ->
      switch attribute
        when 'name' then @requiredString
        when 'phonology' then @requiredPhonology
        when 'morphology' then @requiredMorphology
        when 'language_model' then @requiredLanguageModel
        else null

    requiredPhonology: (value) ->
      error = null
      if _.isEmpty @get('phonology')
        error = 'You must specify a phonology when creating a morphological
          parser'
      error

    requiredMorphology: (value) ->
      error = null
      if _.isEmpty @get('morphology')
        error = 'You must specify a morphology when creating a morphological
          parser'
      error

    requiredLanguageModel: (value) ->
      error = null
      if _.isEmpty @get('language_model')
        error = 'You must specify a language model when creating a morphological
          parser'
      error

    manyToOneAttributes: [
      'phonology'
      'morphology'
      'language_model'
    ]

