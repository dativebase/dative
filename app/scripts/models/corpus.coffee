define [
  'underscore'
  'backbone'
  './base'
  './../utils/utils'
], (_, Backbone, BaseModel, utils) ->

  # Corpus Model
  # ------------
  #
  # A model for FieldDB corpora. A `CorpusModel` is instantiated with one of
  # the corpus (metadata) objects in the `corpuses` array of the `user` object
  # that is returned when a user logs in.
  #
  # A corpus model's data must be retrieved by two requests. The first retrieves
  # the bulk of the corpus data while the second returns the users with access
  # to the corpus.
  #
  # 1. GET `<CorpusServiceURL>/<corpusname>/_design/pages/_view/private_corpuses`
  # 2. POST `<AuthServiceURL>/corpusteam` with a payload object with the
  #    attributes `authUrl`, `pouchname`, `serverCode`, and `username`.

  class CorpusModel extends BaseModel

    initialize: (options) ->
      @metadata = options.metadata
      @applicationSettings = options.applicationSettings

    getURL:  ->
      protocol = @metadata.protocol
      domain = @metadata.domain
      port = if @metadata.port then ":#{@metadata.port}" else ''
      pouchname = @metadata.pouchname

      # QUESTION @cesine: why does the Spreadsheet app request
      # `_view/private_corpuses` but this view does not exist on my (recently
      # created) couches. Using `_view/corpuses` works though...
      ["#{protocol}#{domain}#{port}/#{pouchname}",
       "/_design/pages/_view/private_corpuses"].join('')

    # GET `<CorpusServiceURL>/<corpusname>/_design/pages/_view/corpuses`
    fetch: ->
      CorpusModel.cors.request(
        method: 'GET'
        timeout: 10000
        url: @getURL()
        onload: (responseJSON) =>
          fieldDBCorpusObject = responseJSON.rows?[0].value or {}
          @set fieldDBCorpusObject
          @fetchUsers()
        onerror: (responseJSON) =>
          console.log "Failed to fetch a corpus at #{@url()}."
        ontimeout: =>
          console.log "Failed to fetch a corpus at #{@url()}. Request timed out."
      )

    # POST `<AuthServiceURL>/corpusteam` with a payload containing `authUrl`,
    # `username`, `pouchname`, and `serverCode`.
    fetchUsers: ->
      # QUESTION @cesine: Is there a good reason that the Spreadsheet app
      # passes the password in the payload to /corpusteam? It doesn't look like
      # `fetchCorpusPermissions` needs it in
      # `AuthenticationWebService/lib/userauthentication.js`. Also, the request
      # works without `password` in the payload.
      authUrl = @applicationSettings.get?('activeServer')?.get?('url')
      payload =
        # authUrl: @get('couchConnection')?.authUrl
        authUrl: authUrl
        username: @applicationSettings.get?('username')
        pouchname: @get 'pouchname'
        serverCode: @applicationSettings.get?('activeServer')?.get?('serverCode')
      CorpusModel.cors.request(
        method: 'POST'
        timeout: 10000
        url: "#{payload.authUrl}/corpusteam"
        payload: payload
        onload: (responseJSON) =>
          if responseJSON.users
            @set 'users', responseJSON.users
            @trigger 'usersFetched'
          else
            console.log 'Failed request to /corpusteam: no users attribute.'
        onerror: (responseJSON) =>
          console.log 'Failed request to /corpusteam: error.'
        ontimeout: =>
          console.log 'Failed request to /corpusteam: timed out.'
      )

