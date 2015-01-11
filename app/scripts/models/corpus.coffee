define [
  'underscore'
  'backbone'
  './base'
  './../utils/utils'
], (_, Backbone, BaseModel, utils) ->

  # Corpus Model
  # ------------
  #
  # A model for FieldDB corpora. A `CorpusModel` is instantiated with a pouchname
  # for the corpus. This is a unique, spaceless, lowercase name that begins with
  # its creator's username.
  #
  # A corpus model's data must be retrieved by two requests. (1) retrieves the
  # bulk of the corpus data while (2) returns the users with access to the
  # corpus:
  #
  # 1. @fetch
  # 2. @fetchUsers
  #
  # Two other server-request methods are defined here:
  #
  # 3. @removeUserFromCorpus
  # 4. @grantRoleToUser

  class CorpusModel extends BaseModel

    initialize: (options) ->
      @applicationSettings = options.applicationSettings
      @pouchname = options.pouchname

    getCorpusServerURL:  ->
      "#{@applicationSettings.get('baseDBURL')}/#{@pouchname}"

    # Fetch the corpus data.
    # GET `<CorpusServiceURL>/<corpusname>/_design/pages/_view/private_corpuses`
    fetch: ->
      @trigger 'fetchStart'
      CorpusModel.cors.request(
        method: 'GET'
        timeout: 10000
        url: "#{@getCorpusServerURL()}/_design/pages/_view/private_corpuses"
        onload: (responseJSON) =>
          #fieldDBCorpusObject = responseJSON.rows?[-1].value or {}
          fieldDBCorpusObject = @getFieldDBCorpusObject responseJSON
          console.log fieldDBCorpusObject
          @set fieldDBCorpusObject
          @trigger 'fetchEnd'
        onerror: (responseJSON) =>
          console.log "Failed to fetch a corpus at #{@url()}."
          @trigger 'fetchEnd'
        ontimeout: =>
          console.log "Failed to fetch a corpus at #{@url()}. Request timed out."
          @trigger 'fetchEnd'
      )

    getFieldDBCorpusObject: (responseJSON) ->
      result = {}
      if responseJSON.rows?
        [..., tmp] = responseJSON.rows # Last element in array, a la CoffeeScript
        result = tmp.value

    getDefaultPayload: ->
      authUrl: @applicationSettings.get?('activeServer')?.get?('url')
      username: @applicationSettings.get?('username')
      password: @applicationSettings.get?('password')
      serverCode: @applicationSettings.get?('activeServer')?.get?('serverCode')
      pouchname: @get 'pouchname'

    # Fetch the users with access to a corpus.
    # POST `<AuthServiceURL>/corpusteam`
    fetchUsers: ->
      @trigger 'fetchUsersStart'
      payload = @getDefaultPayload()
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

    # Grant a role on a corpus to a user.
    # POST `<AuthServiceURL>/updateroles`
    grantRoleToUser: (role, username) ->
      @trigger 'grantRoleToUserStart'
      payload = @getDefaultPayload()
      payload.userRoleInfo =
        admin: if role is 'admin' then true else false
        writer: if role is 'reader' then false else true
        reader: true
        pouchname: payload.pouchname
        role: @getFieldDBRole role
        usernameToModify: username
      CorpusModel.cors.request(
        method: 'POST'
        timeout: 10000
        url: "#{payload.authUrl}/updateroles"
        payload: payload
        onload: (responseJSON) =>
          @trigger 'grantRoleToUserEnd'
          if responseJSON.corpusadded
            @trigger 'grantRoleToUserSuccess', role, username
          else
            console.log 'Failed request to /updateroles: no `corpusadded` attribute.'
        onerror: (responseJSON) =>
          @trigger 'grantRoleToUserEnd'
          console.log 'Failed request to /updateroles: error.'
        ontimeout: =>
          @trigger 'grantRoleToUserEnd'
          console.log 'Failed request to /updateroles: timed out.'
      )

    # Remove a user from a corpus.
    # POST `<AuthServiceURL>/updateroles`
    removeUserFromCorpus: (username) ->
      @trigger 'removeUserFromCorpusStart'
      payload = @getDefaultPayload()
      payload.userRoleInfo =
        pouchname: payload.pouchname
        removeUser: true
        usernameToModify: username
      CorpusModel.cors.request(
        method: 'POST'
        timeout: 10000
        url: "#{payload.authUrl}/updateroles"
        payload: payload
        onload: (responseJSON) =>
          @trigger 'removeUserFromCorpusEnd'
          if responseJSON.corpusadded
            @trigger 'removeUserFromCorpusSuccess', username
          else
            console.log 'Failed request to /updateroles: no `corpusadded` attribute.'
        onerror: (responseJSON) =>
          @trigger 'removeUserFromCorpusEnd'
          console.log 'Failed request to /updateroles: error.'
        ontimeout: =>
          @trigger 'removeUserFromCorpusEnd'
          console.log 'Failed request to /updateroles: timed out.'
      )

