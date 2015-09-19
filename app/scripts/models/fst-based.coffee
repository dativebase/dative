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
    applyDown: (words) -> @apply words, 'down'

    # Perform an "apply up" request on the FST-based resource.
    # For example, ask that an impoverished morphological segmentation be
    # converted to a rich representation for input to a candidate ranker during
    # parsing.
    # Example request: PUT `<URL>/morphologies/{id}/applyup`.
    applyUp: (words) -> @apply words, 'up'

    # Perform an "apply" request on the FST-based resource, where `direction`
    # is "up" or "down", this determining whether the request is an "apply up"
    # one or an "apply down" one.
    apply: (words, direction='down') ->
      directionCapitalized = @utils.capitalize direction
      @trigger "apply#{directionCapitalized}Start"
      @constructor.cors.request(
        method: 'PUT'
        url: "#{@getOLDURL()}/#{@getServerSideResourceName()}/\
          #{@get 'id'}/apply#{direction}"
        payload: @["getApply#{directionCapitalized}Payload"] words
        onload: (responseJSON, xhr) =>
          @trigger "apply#{directionCapitalized}End"
          if xhr.status is 200
            @trigger "apply#{directionCapitalized}Success", responseJSON
          else
            error = responseJSON.error or 'No error message provided.'
            @trigger "apply#{directionCapitalized}Fail", error
            console.log "PUT request to
              #{@getOLDURL()}/#{@getServerSideResourceName()}/#{@get 'id'}/\
              apply#{direction} failed (status not 200)."
            console.log error
        onerror: (responseJSON) =>
          @trigger "apply#{directionCapitalized}End"
          error = responseJSON.error or 'No error message provided.'
          @trigger "apply#{directionCapitalized}Fail", error
          console.log "Error in PUT request to
            #{@getOLDURL()}/#{@getServerSideResourceName()}/#{@get 'id'}/\
              apply#{direction} (onerror triggered)."
      )

    # Input in body of HTTP request that phonology resources expect:
    # ``{'transcriptions': [t1, t2, ...]}``.
    getApplyDownPayload: (words) ->
      if @resourceName is 'phonology'
        {transcriptions: words.split(/\s+/)}
      else
        {morpheme_sequences: words.split(/\s+/)}

    getApplyUpPayload: (words) -> @getApplyDownPayload words

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


