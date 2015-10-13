define [
  './fst-based'
  './../utils/globals'
], (FSTBasedModel, globals) ->

  # Phonology Model
  # ---------------
  #
  # A Backbone model for Dative phonologies.
  #
  # Note: this model has extensive logic for cacheing "apply down" request
  # results in localStorage on the client. This functionality should be
  # generalized for other FST-based resources and moved to `FSTBasedModel` in
  # the future.

  class PhonologyModel extends FSTBasedModel

    resourceName: 'phonology'

    initialize: (attributes, options) ->
      super attributes, options
      @listenTo @, 'change:compile_attempt', @resetApplyDownCache
      @applyDownCache = @fetchApplyDownCache()

    # Each phonology resource has a cache in localStorage whose key is a unique
    # string constructed from the web service's URL and the phonology's last
    # compile_attempt value. Note that multiple `PhonologyModel` instances can
    # exist in a Dative app and they will (should) all access and modify the
    # same localStorage cache, as needed.
    getLocalStorageKey: (previous=false) ->
      serverURL = globals.applicationSettings.get('activeServer').get 'url'
      if previous
        compileAttempt = @previousAttributes().compile_attempt
      else
        compileAttempt = @get 'compile_attempt'
      if compileAttempt
        "dative-#{serverURL}-phonology-#{compileAttempt}-applydown-cache"
      else
        null

    # Fetch our client-side-stored (in localStorage) cache of "apply down"
    # mappings.
    fetchApplyDownCache: ->
      key = @getLocalStorageKey()
      if key
        localStorageCache = localStorage.getItem key
        if localStorageCache
          JSON.parse localStorageCache
        else
          localStorage.setItem key, JSON.stringify({})
          {}
      else
        console.log "WARN: unable to get persisted cache: this phonology has no
          `compile_attempt` attribute"
        {}

    # Save the in-memory cache of "apply down" results to localStorage.
    persistApplyDownCache: ->
      key = @getLocalStorageKey()
      if key
        localStorage.setItem key, JSON.stringify(@applyDownCache)
      else
        console.log "WARN: unable to persist cache: this phonology has no
          `compile_attempt` attribute"

    # We delete our old localStorage apply down cache and create a new one when
    # our PhonologyModel's `compile_attempt` attribute changes. This attribute
    # changing usually means that the phonology will behave differently, though
    # that isn't necessarily true if the compile was made with no change in the
    # phonology's script.
    # TODO: make this reset sensitive to `PhonologyModel.script` content: if
    # script hasn't changed, then don't delete the cache, just copy it over to
    # the new localStorage address.
    resetApplyDownCache: ->
      previousLocalStorageKey = @getLocalStorageKey true
      currentLocalStorageKey = @getLocalStorageKey()
      localStorage.removeItem previousLocalStorageKey
      @applyDownCache = {}
      @persistApplyDownCache()

    # Cache our apply down results from the server in memory and in
    # localStorage.
    cacheApplyDownResults: (applyDownResults) ->
      for uf, sfSet of applyDownResults
        @applyDownCache[uf] = sfSet
      @persistApplyDownCache()

    # The `PhonologyModel` overrides the super-class's `applyDown` method in
    # order to provide in-memory and client-side localStorage caching of parser
    # results. We try to minimize requests to the server and to minimize how
    # many words are sent to the server for "apply down" transformation on all
    # necessary requests.
    applyDown: (words) ->
      wordsNeedingApplyDown =
        (w for w in words when w not of @applyDownCache)
      if wordsNeedingApplyDown.length > 0
        # We remember the words that we already have (cached) outputs for so we
        # can add them to the server's response on a successful request. See
        # the `applyOnloadHandler` below.
        @wordsCached = (w for w in words when w of @applyDownCache)
        super wordsNeedingApplyDown
      else
        # Client-side retrieval of cached apply down results. Note we use the
        # same API, i.e., we trigger the same events that a successful request
        # to the server would.
        @trigger "applyDownStart"
        result = {}
        for word in words
          result[word] = @applyDownCache[word]
        @trigger "applyDownSuccess", result
        @trigger "applyDownEnd"

    # Respond to a successful "apply down" request to the server. The override
    # here is needed in order to:
    # 1. cache the results from the server
    # 2. add our cached response to the object passed to any 'applyDownSuccess'
    #    listeners.
    applyOnloadHandler: (responseJSON, xhr, directionCapitalized) ->
      @trigger "apply#{directionCapitalized}End"
      if xhr.status is 200
        @cacheApplyDownResults responseJSON
        if @wordsCached and @wordsCached.length > 0
          for word in @wordsCached
            responseJSON[word] = @applyDownCache[word]
        @trigger "apply#{directionCapitalized}Success", responseJSON
      else
        error = responseJSON.error or 'No error message provided.'
        @trigger "apply#{directionCapitalized}Fail", error
        console.log "PUT request to
          #{@getOLDURL()}/#{@getServerSideResourceName()}/#{@get 'id'}/\
          apply#{direction} failed (status not 200)."
        console.log error

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

    # Perform a "run tests" request on the phonology.
    # GET `<URL>/phonologies/{id}/runtests`
    runTests: ->
      @trigger "runTestsStart"
      @constructor.cors.request(
        method: 'GET'
        url: "#{@getOLDURL()}/phonologies/#{@get 'id'}/runtests"
        onload: (responseJSON, xhr) =>
          @trigger "runTestsEnd"
          if xhr.status is 200
            @trigger "runTestsSuccess", responseJSON
          else
            error = responseJSON.error or 'No error message provided.'
            @trigger "runTestsFail", error
            console.log "PUT request to
              #{@getOLDURL()}/phonologies/#{@get 'id'}/runtests
              failed (status not 200)."
            console.log error
        onerror: (responseJSON) =>
          @trigger "runTestsEnd"
          error = responseJSON.error or 'No error message provided.'
          @trigger "runTestsFail", error
          console.log "Error in PUT request to
            #{@getOLDURL()}/phonologies/#{@get 'id'}/runtests
            (onerror triggered)."
      )

