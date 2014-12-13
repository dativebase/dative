define [
  'underscore'
  'backbone'
  './base-relational'
  './server'
  './../collections/servers'
  './../utils/utils'
  'backbonelocalstorage'
], (_, Backbone, BaseRelationalModel, ServerModel, ServersCollection, utils) ->

  # Application Settings Model
  # --------------------------
  #
  # Holds server configuration and (in the future) other stuff.
  # Persisted in the browser using localStorage (Backbone.localStorage)
  #
  # Uses Backbone-relational to facilitate the auto-generation of sub-models
  # and sub-collections. See the `relations` attribute.
  #
  # Also contains the authentication logic.

  class ApplicationSettingsModel extends BaseRelationalModel

    initialize: ->
      @listenTo Backbone, 'authenticate:login', @authenticate
      @listenTo Backbone, 'authenticate:logout', @logout
      @listenTo Backbone, 'authenticate:register', @register
      @listenTo @, 'change:activeServer', @activeServerChanged
      if @get('activeServer')
        @listenTo @get('activeServer'), 'change:url', @activeServerURLChanged
      if not Modernizr.localstorage
        throw new Error 'localStorage unavailable in this browser, please upgrade.'

    activeServerChanged: ->
      #console.log 'active server has changed says the app settings model'

    activeServerURLChanged: ->
      #console.log 'active server URL has changed says the app settings model'

    _getURL: ->
      url = @get('activeServer')?.get('url')
      if url.slice(-1) is '/' then url.slice(0, -1) else url

    _authenticateAttemptDone: (taskId) ->
      Backbone.trigger 'longTask:deregister', taskId
      Backbone.trigger 'authenticate:end'


    # Login (a.k.a. authenticate)
    #=========================================================================

    # Attempt to authenticate with the passed-in credentials
    authenticate: (username, password) ->
      if @get('activeServer')?.get('type') is 'FieldDB'
        @_authenticateFieldDB username: username, password: password
      else
        @_authenticateOLD username: username, password: password

    _authenticateOLD: (credentials) ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'authenticating', taskId
      BaseRelationalModel.cors.request(
        method: 'POST'
        timeout: 3000
        url: "#{@_getURL()}/login/authenticate"
        payload: credentials
        onload: (responseJSON) =>
          @_authenticateAttemptDone taskId
          if responseJSON.authenticated is true
            @save username: credentials.username, loggedIn: true
            Backbone.trigger 'authenticate:success'
          else
            Backbone.trigger 'authenticate:fail', responseJSON
        onerror: (responseJSON) =>
          Backbone.trigger 'authenticate:fail', responseJSON
          @_authenticateAttemptDone taskId
        ontimeout: =>
          Backbone.trigger 'authenticate:fail', error: 'Request timed out'
          @_authenticateAttemptDone taskId
      )

    # This is based on the FieldDB AngularJS ("Spreadsheet") source, i.e.,
    # https://github.com/OpenSourceFieldlinguistics/FieldDB/blob/master/\
    #   angular_client/modules/core/app/scripts/directives/\
    #   fielddb-authentication.js
    _authenticateFieldDB: (credentials) ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'authenticating', taskId
      FieldDB.Database::BASE_AUTH_URL = @_getURL()
      FieldDB.Database::login(credentials).then(
        (user) =>
          # TODO @jrwdunham: insert a test on the `user` object here.
          @save username: credentials.username, loggedIn: true
          Backbone.trigger 'authenticate:success'
          user = new FieldDB.User(user)
          # TODO @jrwdunham: store the returned user somewhere
        ,
        (reason) ->
          Backbone.trigger 'authenticate:fail', reason
      ).catch(
        ->
          Backbone.trigger 'authenticate:fail', {reason: 'An error occurred'}
      ).done(
        =>
          @_authenticateAttemptDone taskId
      )


    # Logout
    #=========================================================================

    logout: ->
      if @get('activeServer')?.get('type') is 'FieldDB'
        @_logoutFieldDB()
      else
        @_logoutOLD()

    _logoutOLD: ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'logout', taskId
      BaseRelationalModel.cors.request(
        url: "#{@_getURL()}/login/logout"
        method: 'GET'
        timeout: 3000
        onload: (responseJSON) =>
          @_authenticateAttemptDone taskId
          if responseJSON.authenticated is false
            @save 'loggedIn', false
            Backbone.trigger 'logout:success'
          else
            Backbone.trigger 'logout:fail'
        onerror: (responseJSON) =>
          @_authenticateAttemptDone taskId
          Backbone.trigger 'logout:fail'
        ontimeout: =>
          @_authenticateAttemptDone taskId
          Backbone.trigger 'logout:fail', error: 'Request timed out'
      )

    _logoutFieldDB: ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'logout', taskId
      FieldDB.Database::BASE_AUTH_URL = @_getURL()
      FieldDB.Database::logout().then(
        (responseJSON) =>
          if responseJSON.ok is true
            @save 'loggedIn', false
            Backbone.trigger 'logout:success'
          else
            Backbone.trigger 'logout:fail',
              "server #{@_getURL()} did not accept logout request."
        ,
        (reason) ->
          Backbone.trigger 'logout:fail', reason
      ).done(=> @_authenticateAttemptDone taskId)


    # Check if logged in
    #=========================================================================

    # Check if we are already logged in.
    checkIfLoggedIn: ->
      if @get('activeServer')?.get('type') is 'FieldDB'
        @_checkIfLoggedInFieldDB()
      else
        @_checkIfLoggedInOLD()

    _checkIfLoggedInOLD: ->
      taskId = @guid()
      Backbone.trigger('longTask:register', 'checking if already logged in',
        taskId)
      BaseRelationalModel.cors.request(
        url: "#{@_getURL()}/speakers"
        timeout: 3000
        onload: (responseJSON) =>
          @_authenticateAttemptDone(taskId)
          if utils.type(responseJSON) is 'array'
            @save 'loggedIn', true
            Backbone.trigger 'authenticate:success'
          else
            @save 'loggedIn', false
            Backbone.trigger 'authenticate:fail'
        onerror: (responseJSON) =>
          @save 'loggedIn', false
          Backbone.trigger 'authenticate:fail', responseJSON
          @_authenticateAttemptDone(taskId)
        ontimeout: =>
          @save 'loggedIn', false
          Backbone.trigger 'authenticate:fail', error: 'Request timed out'
          @_authenticateAttemptDone(taskId)
      )

    _checkIfLoggedInFieldDB: ->
      taskId = @guid()
      Backbone.trigger('longTask:register', 'checking if already logged in',
        taskId)
      FieldDB.Database::resumeAuthenticationSession().then(
        (sessionInfo) =>
          if sessionInfo.ok and sessionInfo.userCtx.name
            @save 'loggedIn', true
            Backbone.trigger 'authenticate:success'
          else
            @save 'loggedIn', false
            Backbone.trigger 'authenticate:fail'
        ,
        (reason) =>
          @save 'loggedIn', false
          Backbone.trigger 'authenticate:fail', reason
      ).done(=> @_authenticateAttemptDone taskId)


    # Register a new user
    # =========================================================================

    # `RegisterDialogView` should never allow an OLD registration attempt.
    register: (params) ->
      if @get('activeServer')?.get('type') is 'FieldDB'
        @_registerFieldDB params

    _registerFieldDB: (params) ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'registering a new user', taskId

      params.authUrl = @_getURL()
      # TODO @cesine: `appVersionWhenCreated`: should it be Dative current version?
      params.appVersionWhenCreated = 'placeholder'

      BaseRelationalModel.cors.request(
        url: "#{@_getURL()}/register"
        payload: params
        method: 'POST'
        timeout: 10000 # FieldDB auth can take some time to register a new user ...
        onload: (responseJSON) =>
          @_authenticateAttemptDone taskId
          # TODO @cesine: what other kinds of responses to registration requests
          # can the auth service make?
          if responseJSON.user?
            Backbone.trigger 'register:success', responseJSON
          else
            Backbone.trigger 'register:fail', responseJSON.userFriendlyErrors
        onerror: (responseJSON) =>
          @_authenticateAttemptDone taskId
          Backbone.trigger 'register:fail', 'server responded with error'
        ontimeout: =>
          @_authenticateAttemptDone taskId
          Backbone.trigger 'register:fail', 'Request timed out'
      )


    # Backbone-relational stuff
    # =========================================================================
    #
    # This is useful because it auto-creates a model hierachy; e.g.,
    # `@get('activeServer')` returns a `ServerModel` instance and
    # `@get('servers')` returns a `ServerCollection` instance.
    #
    # See http://backbonerelational.org/#RelationalModel-relations

    idAttribute: 'id'

    relations: [
        type: Backbone.HasMany
        key: 'servers'
        relatedModel: ServerModel
        collectionType: ServersCollection
        includeInJSON: ['id', 'name', 'type', 'url']
        reverseRelation:
          key: 'applicationSettings'
      ,
        type: Backbone.HasOne
        key: 'activeServer'
        relatedModel: ServerModel
        includeInJSON: 'id'
    ]


    # Defaults
    #=========================================================================

    defaults: ->

      server1 =
        id: @guid()
        name: 'FieldDB Development'
        type: 'FieldDB'
        url: 'https://localhost:3183'
        serverCode: 'localhost'

      server2 =
        id: @guid()
        name: 'OLD Development'
        type: 'OLD'
        url: 'http://127.0.0.1:5000'

      server3 =
        id: @guid()
        name: 'FieldDB'
        type: 'FieldDB'
        url: 'https://auth.lingsync.org'
        serverCode: 'production'

      server4 =
        id: @guid()
        name: 'OLD'
        type: 'OLD'
        url: 'http://www.onlinelinguisticdatabase.org'

      id: @guid()
      activeServer: server1.id
      loggedIn: false
      username: ''
      servers: [server1, server2, server3, server4]
      serverTypes: ['FieldDB', 'OLD']
      fieldDBServerCodes: [
        'localhost'
        'testing'
        'beta'
        'production'
        'mcgill'
        'concordia'
        'dyslexdisorth'
      ]
      itemsPerPage: 10

  # Backbone-relational requires this when using CoffeeScript
  ApplicationSettingsModel.setup()

