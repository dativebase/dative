define [
  './fst-based'
  './../utils/globals'
], (FSTBasedModel, globals) ->

  # Phonology Model
  # ---------------
  #
  # A Backbone model for Dative phonologies.

  class PhonologyModel extends FSTBasedModel

    resourceName: 'phonology'

    initialize: (attributes, options) ->
      super attributes, options
      @listenTo @, 'change:compile_attempt', @resetApplyDownCache
      @applyDownCache = @fetchApplyDownCache()

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

    persistApplyDownCache: ->
      key = @getLocalStorageKey()
      if key
        localStorage.setItem key, JSON.stringify(@applyDownCache)
      else
        console.log "WARN: unable to persist cache: this phonology has no
          `compile_attempt` attribute"

    resetApplyDownCache: ->
      previousLocalStorageKey = @getLocalStorageKey true
      currentLocalStorageKey = @getLocalStorageKey()
      console.log "in resetApplyDownCache.\nDeleting\n#{previousLocalStorageKey}\nAdding\n#{currentLocalStorageKey}"
      localStorage.removeItem previousLocalStorageKey
      @applyDownCache = {}
      @persistApplyDownCache()

    cacheApplyDownResults: (applyDownResults) ->
      for uf, sfSet of applyDownResults
        @applyDownCache[uf] = sfSet
      @persistApplyDownCache()

    applyDown_: (words) ->
      wordsNeedingApplyDown =
        (w for w in words when w not of @applyDownCache)
      if wordsNeedingApplyDown.length > 0
        # TODO: is this going to wreck the super-class's listening-to of this
        # applyDownSuccess event?
        @listenToOnce @, 'applyDownSuccess', @cacheApplyDownResults
        super words
      else
        console.log 'Apply Down from Cache (no need to request from server)'
        @trigger "applyDownStart"
        result = {}
        for word in wordsNeedingApplyDown
          result[word] = @applyDownCache[word]
        @trigger "applyDownSuccess", result
        @trigger "applyDownEnd"

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

