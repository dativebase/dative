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

    # Perform a "compile" request.
    # PUT `<URL>/phonologies/{id}/compile`
    compile: ->
      @trigger "compileStart"
      @constructor.cors.request(
        method: 'PUT'
        url: "#{@getOLDURL()}/phonologies/#{@get 'id'}/compile"
        onload: (responseJSON, xhr) =>
          @trigger "compileEnd"
          if xhr.status is 200
            @trigger "compileSuccess", responseJSON
          else
            error = responseJSON.error or 'No error message provided.'
            @trigger "compileFail", error
            console.log "PUT request to
              #{@getOLDURL()}/phonologies/#{@get 'id'}/compile
              failed (status not 200)."
            console.log error
        onerror: (responseJSON) =>
          @trigger "compileEnd"
          error = responseJSON.error or 'No error message provided.'
          @trigger "compileFail", error
          console.log "Error in PUT request to
            #{@getOLDURL()}/phonologies/#{@get 'id'}/compile
            (onerror triggered)."
      )


    # Perform an "apply down" request on the phonology, i.e., ask that a
    # morphological segmentation be phonologized, that is, converted to its
    # surface form, given the phonology.
    # PUT `<URL>/phonologies/{id}/applydown` (alias to PUT
    # /phonologies/{id}/phonologize).
    applyDown: (words) ->
      @trigger "applyDownStart"
      @constructor.cors.request(
        method: 'PUT'
        url: "#{@getOLDURL()}/phonologies/#{@get 'id'}/applydown"
        payload: @getApplyDownPayload words
        onload: (responseJSON, xhr) =>
          @trigger "applyDownEnd"
          if xhr.status is 200
            @trigger "applyDownSuccess", responseJSON
          else
            error = responseJSON.error or 'No error message provided.'
            @trigger "applyDownFail", error
            console.log "PUT request to
              #{@getOLDURL()}/phonologies/#{@get 'id'}/applydown
              failed (status not 200)."
            console.log error
        onerror: (responseJSON) =>
          @trigger "applyDownEnd"
          error = responseJSON.error or 'No error message provided.'
          @trigger "applyDownFail", error
          console.log "Error in PUT request to
            #{@getOLDURL()}/phonologies/#{@get 'id'}/applydown
            (onerror triggered)."
      )

    # Input in body of HTTP request expected
    # ``{'transcriptions': [t1, t2, ...]}``.
    getApplyDownPayload: (words) ->
      {transcriptions: words.split(/\s+/)}

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

    # Perform a "serve compiled" request on the phonology.
    # GET `<URL>/phonologies/{id}/servecompiled`
    serveCompiled: ->
      @trigger "serveCompiledStart"
      @constructor.cors.request(
        responseType: 'blob'
        method: 'GET'
        url: "#{@getOLDURL()}/phonologies/#{@get 'id'}/servecompiled"
        onload: (responseJSON, xhr) =>
          @trigger "serveCompiledEnd"
          if xhr.status is 200
            @trigger "serveCompiledSuccess", responseJSON
          else
            error = responseJSON.error or 'No error message provided.'
            @trigger "serveCompiledFail", error
            console.log "GET request to
              #{@getOLDURL()}/phonologies/#{@get 'id'}/servecompiled
              failed (status not 200)."
            console.log error
        onerror: (responseJSON) =>
          @trigger "serveCompiledEnd"
          error = responseJSON.error or 'No error message provided.'
          @trigger "serveCompiledFail", error
          console.log "Error in GET request to
            #{@getOLDURL()}/phonologies/#{@get 'id'}/servecompiled
            (onerror triggered)."
      )

