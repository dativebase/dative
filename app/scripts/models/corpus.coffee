define [
  'underscore'
  'backbone'
  './base'
  './../utils/utils'
], (_, Backbone, BaseModel, utils) ->

  # Corpus Model
  # ------------
  #
  # A model for FieldDB corpora. A `CorpusModel` is instantiated with a dbname
  # for the corpus. This is a unique, spaceless, lowercase name that is namespaced with
  # its team's username.
  #
  # A corpus model's data must be retrieved by two requests. (1) retrieves the
  # bulk of the corpus data while (2) returns the users with access to the
  # corpus:
  #
  # 1. @fetch
  # 2. @fetchUsers
  #
  # Three other server-request methods are defined here:
  #
  # 3. @removeUserFromCorpus
  # 4. @grantRoleToUser
  # 5. @updateCorpus

  class CorpusModel extends BaseModel

    initialize: (options) ->
      console.log 'Initializing backbone corpus model with a fielddb corpus model inside of it', this.attributes
      @corpus = new FieldDB.Corpus(options)
      if @corpus.connection and @corpus.connection.corpusid 
        @corpus.id = @corpus.connection.corpusid
        # @corpus.fetch().then(()=>{
        #     console.log 'Could cause corpus to re-render, it has more info now.'
        #   })
      if not @corpus.title and @corpus.connection.title
        @corpus.title = @corpus.connection.title
      if not @corpus.description and @corpus.connection.description
        @corpus.description = @corpus.connection.description
      # @applicationSettings = options.applicationSettings
      # @dbname = options.dbname

    ############################################################################
    # CORS methods
    ############################################################################

    # Fetch the corpus data.
    # GET `<CorpusServiceURL>/<corpusname>/_design/deprecated/_view/private_corpuses`
    fetch: ->
      @trigger 'fetchStart'
      @corpus.fetch().then(
        (response) =>
          console.log 'success'
          console.log response
          @trigger 'fetchSuccess'
      ,
        (error) =>
          console.log 'error'
          @trigger 'fetchFail'
      ).done =>
        @trigger 'fetchEnd'

    oldfetch: ->
      @trigger 'fetchStart'
      CorpusModel.cors.request(
        method: 'GET'
        timeout: 10000
        url: "#{@getCorpusServerURL()}/_design/deprecated/_view/private_corpuses"
        onload: (responseJSON) =>
          fieldDBCorpusObject = @getFieldDBCorpusObject responseJSON
          # TODO @jrwdunham: should this `set` be a `save`?
          if fieldDBCorpusObject then @set fieldDBCorpusObject
          @trigger 'fetchEnd'
        onerror: (responseJSON) =>
          console.log "Failed to fetch a corpus at #{@url()}."
          @trigger 'fetchEnd'
        ontimeout: =>
          console.log "Failed to fetch a corpus at #{@url()}. Request timed out."
          @trigger 'fetchEnd'
      )

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

    # Grant a role on a corpus to a user.
    # POST `<AuthServiceURL>/updateroles`
    grantRoleToUser: (role, username) ->
      @trigger 'grantRoleToUserStart'
      payload = @getDefaultPayload()
      payload.userRoleInfo =
        admin: if role is 'admin' then true else false
        writer: if role is 'reader' then false else true
        reader: true
        dbname: payload.dbname
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
        dbname: payload.dbname
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

    # NOTE: @jrwdunham, @cesine: NOT IMPLEMENTED
    # See https://github.com/jrwdunham/dative/issues/78

    # Update the details of a corpus
    # PUT `<CorpusServiceURL>/<dbname>/<corpusUUID>
    # QUESTIONS:
    # 1. do I need to manually change `titleAsURL`? What about the other fields?

    # TODO:
    # set title to new title
    # set description to new description
    # update dateModified timestamp: (new Date().getTime()
    # allow user to modify gravatar
    # show gravatar in corpus list
    #
    updateCorpus: (title, description) ->
      console.log 'in updateCorpus of corpus model'
      console.log JSON.stringify(@, undefined, 2)
      # for attr in _.keys(@attributes).sort()
      #   if attr not in ['applicationSettings', 'isActive']
      #     console.log '\n'
      #     console.log attr
      #     console.log JSON.stringify(@attributes[attr])
      #     console.log '\n'

    updateCorpus_: (title, description) ->
      @trigger 'updateCorpusStart'
      payload = @getDefaultPayload()
      payload.userRoleInfo =
        dbname: payload.dbname
        removeUser: true
        usernameToModify: username
      CorpusModel.cors.request(
        method: 'PUT'
        timeout: 10000
        url: "#{payload.authUrl}/updateroles"
        payload: payload
        onload: (responseJSON) =>
          @trigger 'updateCorpusEnd'
          if responseJSON.corpusadded
            @trigger 'updateCorpusSuccess', username
          else
            console.log 'Failed request to /updateroles: no `corpusadded` attribute.'
        onerror: (responseJSON) =>
          @trigger 'updateCorpusEnd'
          console.log 'Failed request to /updateroles: error.'
        ontimeout: =>
          @trigger 'updateCorpusEnd'
          console.log 'Failed request to /updateroles: timed out.'
      )

    ###
    # This is the object that is sent to PUT `<CorpusServiceURL>/<dbname>/<corpusUUID>
    # on an update request. It is
    _id: "63ff8fd7b5be6becbd9e5413b3060dd5"
    _rev: "12-d1e6a51f42377dc3803207bbf6a13baa"
    api: "private_corpuses"
    authUrl: FieldDB.Database.prototype.BASE_AUTH_URL
    collection: "private_corpuses"
    comments: []
    confidential: {fieldDBtype: "Confidential", secretkey: "e14714cb-ddfb-5e4e-bad9-2a75d573dbe0",…}
    conversationFields: [,…]
    copyright: "Default: Add names of the copyright holders of the corpus."
    *** dateModified: 1421953770590 # timestamp of last modification (I think)
    datumFields: [{fieldDBtype: "DatumField", labelFieldLinguists: "Judgement", mask: "grammatical",…},…]
    datumStates: [{color: "success", showInSearchResults: "checked", selected: "selected", state: "Checked"},…]
    dbname: "jrwdunham-firstcorpus"
    description: "Best corpus ever"
    fieldDBtype: "Corpus"
    *** gravatar: "33b8cbbfd6c49148ad31ed95e67b4390"
    license: {title: "Default: Creative Commons Attribution-ShareAlike (CC BY-SA).",…}
    modifiedByUser: {value: "jrwdunham, jrwdunham, jrwdunham, jrwdunham, jrwdunham",…}
    participantFields: [,…]
    dbname: "jrwdunham-firstcorpus"
    publicCorpus: "Private"
    searchKeywords: "Froggo"
    sessionFields: [{fieldDBtype: "DatumField", labelFieldLinguists: "Goal", value: "", mask: "", encryptedValue: "",…},…]
    termsOfUse: {,…}
    *** timestamp: 1399303339523 # timestamp of corpus creation (I think)
    title: "Big Bear Corpus"
    titleAsUrl: "big_bear_corpus"
    url: FieldDB.Database.prototype.BASE_DB_URL+"/jrwdunham-firstcorpus"
    version: "v2.38.16"
    ###

    ############################################################################
    # utility methods
    ############################################################################

    getCorpusServerURL:  ->
      url = @applicationSettings.get 'baseDBURL'
      "#{url}/#{@dbname}"

    getFieldDBCorpusObject: (responseJSON) ->
      result = {}
      if responseJSON.rows?
        [..., tmp] = responseJSON.rows # Last element in array, a la CoffeeScript
        result = tmp.value

    getDefaultPayload: ->
      authUrl: @applicationSettings.get?('activeServer')?.get?('url')
      username: @applicationSettings.get?('username')
      password: @applicationSettings.get?('password') # TODO trigger authenticate:mustconfirmidentity
      serverCode: @applicationSettings.get?('activeServer')?.get?('serverCode')
      dbname: @get 'dbname'

    getFieldDBRole: (role) ->
      switch role
        when 'admin' then 'admin'
        when 'writer' then 'read_write'
        when 'reader' then 'read_only'

