define ['./resource'], (ResourceModel) ->

  # FST-based Model
  # ---------------
  #
  # A Backbone model for resources based on FSTs, i.e., finite-state
  # transducers.

  class FSTBasedModel extends ResourceModel

    # Perform a "compile" request on the FST-based resource.
    # e.g., PUT `<URL>/phonologies/{id}/compile`
    compile: ->
      @trigger "compileStart"
      @constructor.cors.request(
        method: 'PUT'
        url: "#{@getOLDURL()}/#{@getServerSideResourceName()}/#{@get 'id'}/compile"
        onload: (responseJSON, xhr) =>
          @trigger "compileEnd"
          if xhr.status is 200
            @trigger "compileSuccess", responseJSON
          else
            error = responseJSON.error or 'No error message provided.'
            @trigger "compileFail", error
            console.log "PUT request to
              #{@getOLDURL()}/#{@getServerSideResourceName()}/#{@get 'id'}/compile
              failed (status not 200)."
            console.log error
        onerror: (responseJSON) =>
          @trigger "compileEnd"
          error = responseJSON.error or 'No error message provided.'
          @trigger "compileFail", error
          console.log "Error in PUT request to
            #{@getOLDURL()}/#{@getServerSideResourceName()}/#{@get 'id'}/compile
            (onerror triggered)."
      )

    # Perform an "apply down" request on the FST-based resource.
    # For example, ask that a morphological segmentation be phonologized using
    # a phonology; that is, converted the morphological segmentation to its
    # surface form, given the phonology.
    # Example request: PUT `<URL>/phonologies/{id}/applydown` (which is an
    # alias for PUT # /phonologies/{id}/phonologize).
    applyDown: (words) ->
      @trigger "applyDownStart"
      @constructor.cors.request(
        method: 'PUT'
        url: "#{@getOLDURL()}/#{@getServerSideResourceName()}/#{@get 'id'}/applydown"
        payload: @getApplyDownPayload words
        onload: (responseJSON, xhr) =>
          @trigger "applyDownEnd"
          if xhr.status is 200
            @trigger "applyDownSuccess", responseJSON
          else
            error = responseJSON.error or 'No error message provided.'
            @trigger "applyDownFail", error
            console.log "PUT request to
              #{@getOLDURL()}/#{@getServerSideResourceName()}/#{@get 'id'}/applydown
              failed (status not 200)."
            console.log error
        onerror: (responseJSON) =>
          @trigger "applyDownEnd"
          error = responseJSON.error or 'No error message provided.'
          @trigger "applyDownFail", error
          console.log "Error in PUT request to
            #{@getOLDURL()}/#{@getServerSideResourceName()}/#{@get 'id'}/applydown
            (onerror triggered)."
      )

    # Input in body of HTTP request expected
    # ``{'transcriptions': [t1, t2, ...]}``.
    # TODO: is this correct just for phonologies or is this needed for
    # morphologies too?
    getApplyDownPayload: (words) ->
      {transcriptions: words.split(/\s+/)}

    # Perform a "serve compiled" request on the fst-based resource.
    # Example request: GET `<URL>/phonologies/{id}/servecompiled`
    serveCompiled: ->
      @trigger "serveCompiledStart"
      @constructor.cors.request(
        responseType: 'blob'
        method: 'GET'
        url: "#{@getOLDURL()}/#{@getServerSideResourceName()}/#{@get 'id'}/servecompiled"
        onload: (responseJSON, xhr) =>
          @trigger "serveCompiledEnd"
          if xhr.status is 200
            @trigger "serveCompiledSuccess", responseJSON
          else
            error = responseJSON.error or 'No error message provided.'
            @trigger "serveCompiledFail", error
            console.log "GET request to
              #{@getOLDURL()}/#{@getServerSideResourceName()}/#{@get 'id'}/servecompiled
              failed (status not 200)."
            console.log error
        onerror: (responseJSON) =>
          @trigger "serveCompiledEnd"
          error = responseJSON.error or 'No error message provided.'
          @trigger "serveCompiledFail", error
          console.log "Error in GET request to
            #{@getOLDURL()}/#{@getServerSideResourceName()}/#{@get 'id'}/servecompiled
            (onerror triggered)."
      )


