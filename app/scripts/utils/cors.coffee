define [], ->

  # CORS Class
  # ----------
  #
  # For making CORS requests.

  class CORS

    vocal: false

    request: (options={}) ->
      try
        @_request options
      catch error
        if options.onerror
          options.onerror error: error
        else
          console.log error

    updateProgress: (event) ->
      percentComplete = (event.loaded / event.total * 100)
      @progressModel.trigger 'uploadProgress', percentComplete

    # Perform a CORS request, sending JSON to and receiving JSON from a RESTful
    # web service
    _request: (options={}) ->

      url = options.url or throw new Error 'A URL is required for CORS requests'
      method = options.method or 'GET'
      timeout = options.timeout or undefined
      contentType = options.contentType or 'application/json;charset=UTF-8'
      monitorProgress = options.monitorProgress or false
      @progressModel = options.progressModel or null

      [onload, onerror, onloadstart, onabort, onprogress, ontimeout,
      onloadend] =  @_getHandlers options, method, url

      xhr = @_getXHR url, method
      if timeout then xhr.timeout = timeout

      if options.responseType
        xhr.responseType = options.responseType

      xhr.withCredentials = true

      if monitorProgress and xhr.upload
        xhr.upload.onprogress = (event) => @updateProgress event

      if contentType[...9] is 'multipart'
        # This is a multipart/form-data request so we let the browser set the
        # content-type header on its own.
        payload = options.payload
      else
        # This is a JSON request (the default) so we set the content-type
        # header ourselves and JSON-ify the payload.
        # Note: apparently "You cannot add custom headers to an XDR object", cf.
        # http://stackoverflow.com/questions/2657180/setting-headers-in-xdomainrequest-or-activexobjectmicrosoft-xmlhttp
        xhr.setRequestHeader 'Content-Type', contentType
        payload = JSON.stringify(options.payload) or "{}"

      xhr.send(payload)

      xhr.onload = onload
      xhr.onerror = onerror

      xhr.onloadstart = onloadstart
      xhr.onabort = onabort
      xhr.onprogress = onprogress
      xhr.ontimeout = ontimeout
      xhr.onloadend = onloadend

    # Return a new XHR (cross-browser-wise)
    # From http://www.html5rocks.com/en/tutorials/cors/
    _getXHR: (url, method) ->
      xhr = new XMLHttpRequest()
      # Check if the XMLHttpRequest object has a "withCredentials" property.
      # "withCredentials" only exists on XMLHTTPRequest2 objects.
      if 'withCredentials' of xhr
        xhr.open method, url, true
      # Otherwise, check if XDomainRequest. XDomainRequest only exists in IE,
      # and is IE's way of making CORS requests.
      else if typeof XDomainRequest isnt 'undefined'
        xhr = new XDomainRequest()
        xhr.open method, url
      # Otherwise, CORS is not supported by the browser.
      else
        throw new Error 'CORS is not supported by this browser. Try Chrome or
          Firefox'
      xhr

    # Get default request handlers for those not supplied; also, modify some
    # of the handlers so that they receive an object representation of the
    # response body.
    _getHandlers: (options, method, url) ->

      vocal = @vocal

      if 'parseJSON' of options
        parseJSON = options.parseJSON
      else
        parseJSON = true

      onload = options.onload or do (vocal, method, url) ->
        -> if vocal then console.log "Successful request to #{method} #{url}."
      onload = @_jsonify onload, parseJSON

      onerror = options.onerror or do (vocal, method, url) ->
        -> if vocal then console.log "Error requesting #{method} #{url}."
      onerror = @_jsonify onerror, parseJSON

      # Default non-standard request handlers (JSON.parse response bodies?)

      onloadstart = options.onloadstart or do (vocal) ->
        -> if vocal then console.log 'onloadstart: the request has started'

      onabort = options.onabort or do (vocal) ->
        ->
          if vocal
            console.log 'onabort: the request has been aborted. For instance, by
              invoking the abort() method.'

      onprogress = options.onprogress or do (vocal) ->
        ->
          if vocal
            console.log 'onprogress: while loading and sending data.'

      ontimeout = options.ontimeout or do (vocal) ->
        ->
          if vocal
            console.log 'ontimeout: author-specified timeout has passed before
              the request could complete.'

      onloadend = options.onloadend or do (vocal) ->
        ->
          if vocal
            console.log 'onloadend: the request has completed (either in success
              or failure).'

      [onload, onerror, onloadstart, onabort, onprogress, ontimeout, onloadend]

    # Wrap a CORS XHR response event handler so that it receives the response
    # as JSON as its first argument (and the XHR as its second).
    _jsonify: (callback, parseJSON=true) ->
      (xhrProgressEvent) ->
        xhr = xhrProgressEvent.target # previously had `.currentTarget` ...
        try
          if parseJSON
            responseJSON = JSON.parse xhr.responseText
          else
            responseJSON = xhr.responseText
        catch error
          try
            responseJSON = xhr.responseText
          catch error
            responseJSON = xhr.response
        callback responseJSON, xhr


