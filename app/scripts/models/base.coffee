define [
  'underscore'
  'backbone'
  'utils/utils'
], (_, Backbone, utils) ->

  # Base Model
  # ----------
  #
  # Functionality that all models and collections need.

  class BaseModel extends Backbone.Model

    # Perform a CORS request, sending JSON to and receiving JSON from a RESTful
    # web service
    cors: (options={}) ->

      url = options.url or throw new Error 'A URL is required for CORS requests'
      method = options.method or 'GET'
      payload = JSON.stringify(options.payload) or "{}"

      [onload, onerror, onloadstart, onabort, onprogress, ontimeout,
      onloadend] =  @_getHandlers options

      xhr = @_getXHR url, method

      console.log 'in cors'
      console.log "url: #{url}"

      xhr.withCredentials = true
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
    _getHandlers: (options) ->

      onload = @_jsonify(options.onload or ->
        console.log "Successful request to #{method} #{url}.")
      onerror = @_jsonify(options.onerror or ->
        console.log "Error requesting #{method} #{url}.")

      # Default non-standard request handlers (JSON.parse response bodies?)
      onloadstart = options.onloadstart or ->
        console.log 'onloadstart: the request has started'
      onabort = options.onabort or ->
        console.log 'onabort: the request has been aborted. For instance, by
          invoking the abort() method.'
      onprogress = options.onprogress or ->
        console.log 'onprogress: while loading and sending data.'
      ontimeout = options.ontimeout or ->
        console.log 'ontimeout: author-specified timeout has passed before the
          request could complete.'
      onloadend = options.onloadend or ->
        console.log 'onloadend: the request has completed (either in success
          or failure).'

      [onload, onerror, onloadstart, onabort, onprogress, ontimeout, onloadend]

    # Wrap a CORS XHR response event handler so that it receives the response
    # as JSON as its first argument (and the XHR as its second).
    _jsonify: (callback) ->
      (xhrProgressEvent) ->
        xhr = xhrProgressEvent.currentTarget
        try
          responseJSON = JSON.parse xhr.responseText
        catch error
          responseJSON = xhr.responseText
        callback responseJSON, xhr

    guid: utils.guid

    ###

    TODO: figure out why using $.ajax to perform a CORS request was not working
    for me. I tried the following:

    $.ajax(
      type: 'POST'
      url: url
      contentType: 'application/json'
      payload: 
        username: username
        password: password
      xhrFields:
        withCredentials: true
      #headers: {}
      success: ->
        console.log 'success!'
        console.log arguments
      error: ->
        console.log 'error :('
    )
    url = "#{@url}/forms"
    method = 'GET'
    payload = null

    ###

