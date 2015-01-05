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
      ["#{protocol}#{domain}#{port}/#{pouchname}",
       "/_design/pages/_view/private_corpuses"].join('')

    # GET `<CorpusServiceURL>/<corpusname>/_design/pages/_view/corpuses`
    fetch: ->
      @trigger 'fetchStart'
      CorpusModel.cors.request(
        method: 'GET'
        timeout: 10000
        url: @getURL()
        onload: (responseJSON) =>
          fieldDBCorpusObject = responseJSON.rows?[0].value or {}
          @set fieldDBCorpusObject
          @trigger 'fetchEnd'
        onerror: (responseJSON) =>
          console.log "Failed to fetch a corpus at #{@url()}."
          @trigger 'fetchEnd'
        ontimeout: =>
          console.log "Failed to fetch a corpus at #{@url()}. Request timed out."
          @trigger 'fetchEnd'
      )

    # POST `<AuthServiceURL>/corpusteam` with a payload containing `authUrl`,
    # `username`, `pouchname`, and `serverCode`.
    fetchUsers: ->
      @trigger 'fetchUsersStart'
      # QUESTION @cesine: Is there a good reason that the Spreadsheet app
      # passes the password in the payload to /corpusteam? It doesn't look like
      # `fetchCorpusPermissions` needs it in
      # `AuthenticationWebService/lib/userauthentication.js`. Also, the request
      # works without `password` in the payload.
      authURL = @applicationSettings.get?('activeServer')?.get?('url')
      payload =
        authUrl: authURL
        username: @applicationSettings.get?('username')
        password: 'a'
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
            @trigger 'fetchUsersEnd'
          else
            @trigger 'fetchUsersEnd'
            console.log 'Failed request to /corpusteam: no users attribute.'
        onerror: (responseJSON) =>
          @trigger 'fetchUsersEnd'
          console.log 'Failed request to /corpusteam: error.'
        ontimeout: =>
          @trigger 'fetchUsersEnd'
          console.log 'Failed request to /corpusteam: timed out.'
      )

    getFieldDBRole: (role) ->
      switch role
        when 'admin' then 'admin'
        when 'writer' then 'read_write'
        when 'reader' then 'read_only'

    # POST `<AuthServiceURL>/updateroles` with a payload containing `authUrl`,
    # `username`, `pouchname`, and `serverCode`.
    addUserToCorpus: (username, role) ->
      @trigger 'addUserToCorpusStart'
      authURL = @applicationSettings.get?('activeServer')?.get?('url')
      payload =
        authUrl: authURL
        username: @applicationSettings.get?('username')
        password: 'a'
        serverCode: @applicationSettings.get?('activeServer')?.get?('serverCode')
        userRoleInfo:
          admin: if role is 'admin' then true else false
          writer: if role is 'writer' then true else false
          reader: if role is 'reader' then true else false
          pouchname: @get 'pouchname'
          role: @getFieldDBRole role
          usernameToModify: username
      CorpusModel.cors.request(
        method: 'POST'
        timeout: 10000
        url: "#{payload.authUrl}/updateroles"
        payload: payload
        onload: (responseJSON) =>
          if responseJSON.corpusadded
            console.log responseJSON.info[0]
            @trigger 'addUserToCorpusEnd'
            @trigger 'addUserToCorpusSuccess'
          else
            @trigger 'addUserToCorpusEnd'
            console.log 'Failed request to /updateroles: no `corpusadded` attribute.'
        onerror: (responseJSON) =>
          @trigger 'addUserToCorpusEnd'
          console.log 'Failed request to /updateroles: error.'
        ontimeout: =>
          @trigger 'addUserToCorpusEnd'
          console.log 'Failed request to /updateroles: timed out.'
      )

      # 2. POST AUTH_SERVICE/corpusteam with JSON:
      # {
      #   authUrl: "https://auth.lingsync.org"
      #   password: "..."
      #   pouchname: "jrwdunham-blackfoot"
      #   serverCode: "production"
      #   username: "jrwdunham"
      # }
      # Expect: JSON object of users (and roles)
      #
      # 3. GET CORPUS_SERVICE/_users/org.couchdb.user:jrwdunham QUESTION: necessary?
      #
      # Expect: JSON:
      #
      # "{
        # "_id": "org.couchdb.user:jrwdunham",
        # "_rev": "2-dd59dbae9fc8f2c6455c5a98cd288c43",
        # "password_scheme": "pbkdf2",
        # "iterations": 10,
        # "name": "jrwdunham",
        # "roles": [
          # "fielddbuser",
          # "jrwdunham-firstcorpus_admin",
          # "jrwdunham-firstcorpus_commenter",
          # "jrwdunham-firstcorpus_reader",
          # "jrwdunham-firstcorpus_writer",
          # "gina-inuktitut_commenter",
          # "gina-inuktitut_reader",
          # "gina-inuktitut_writer",
          # "lingllama-communitycorpus_commenter",
          # "lingllama-communitycorpus_reader",
          # "lingllama-communitycorpus_writer",
          # "testingharvardimport-firstcorpus_admin",
          # "testingharvardimport-firstcorpus_reader",
          # "testingharvardimport-firstcorpus_writer",
          # "testingharvardimport-hjcopypaste_admin",
          # "testingharvardimport-hjcopypaste_reader",
          # "testingharvardimport-hjcopypaste_writer",
          # "jrwdunham-blackfoot_admin",
          # "jrwdunham-blackfoot_writer",
          # "jrwdunham-blackfoot_reader",
          # "jrwdunham-blackfoot_commenter",
          # "elisekm-eti3_data_tutorial_admin",
          # "elisekm-eti3_data_tutorial_reader",
          # "elisekm-eti3_data_tutorial_writer",
          # "jrwdunham-gitksan_practice_admin",
          # "jrwdunham-gitksan_practice_writer",
          # "jrwdunham-gitksan_practice_reader",
          # "jrwdunham-gitksan_practice_commenter",
          # "jrwdunham-blackfoot_ucalgary_workshop_admin",
          # "jrwdunham-blackfoot_ucalgary_workshop_writer",
          # "jrwdunham-blackfoot_ucalgary_workshop_reader",
          # "jrwdunham-blackfoot_ucalgary_workshop_commenter"
        # ],
        # "previous_rev": "1-38b76b7604734524807868cf18ec5eba",
        # "type": "user",
        # "derived_key": "563df7e28ced77f2a44fe6ff657451bd17205602",
        # "salt": "afff49dddf1a013bcbbaeb009e441657"
      # }"

