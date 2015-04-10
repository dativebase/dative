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

    getURL: ->
      url = @get('activeServer')?.get('url')
      if url.slice(-1) is '/' then url.slice(0, -1) else url

    getCorpusServerURL: ->
      @get('activeServer')?.get 'corpusServerURL'

    getServerCode: ->
      @get('activeServer')?.get 'serverCode'

    authenticateAttemptDone: (taskId) ->
      Backbone.trigger 'longTask:deregister', taskId
      Backbone.trigger 'authenticate:end'


    # Login (a.k.a. authenticate)
    #=========================================================================

    # Attempt to authenticate with the passed-in credentials
    authenticate: (username, password) ->
      if @get('activeServer')?.get('type') is 'FieldDB'
        @authenticateFieldDB username: username, password: password
        # @authenticateFieldDBAuthService username: username, password: password
      else
        @authenticateOLD username: username, password: password

    authenticateOLD: (credentials) ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'authenticating', taskId
      BaseRelationalModel.cors.request(
        method: 'POST'
        timeout: 3000
        url: "#{@getURL()}/login/authenticate"
        payload: credentials
        onload: (responseJSON) =>
          @authenticateAttemptDone taskId
          if responseJSON.authenticated is true
            @save
              username: credentials.username
              password: credentials.password
              loggedIn: true
            Backbone.trigger 'authenticate:success'
          else
            Backbone.trigger 'authenticate:fail', responseJSON
        onerror: (responseJSON) =>
          Backbone.trigger 'authenticate:fail', responseJSON
          @authenticateAttemptDone taskId
        ontimeout: =>
          Backbone.trigger 'authenticate:fail', error: 'Request timed out'
          @authenticateAttemptDone taskId
      )

    getFieldDBBaseDBURL: (user) ->
      if user.corpuses?.length
        meta = user.corpuses[0]
        protocol = meta.protocol
        domain = meta.domain
        port = if meta.port then ":#{meta.port}" else ''
        "#{protocol}#{domain}#{port}"

    authenticateFieldDBAuthService: (credentials) ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'authenticating', taskId
      BaseRelationalModel.cors.request(
        method: 'POST'
        timeout: 3000
        url: "#{@getURL()}/login"
        payload: credentials
        onload: (responseJSON) =>
          if responseJSON.user
            # Remember the corpusServiceURL so we can logout.
            @get('activeServer')?.set(
              'corpusServerURL', @getFieldDBBaseDBURL(responseJSON.user))
            @set
              baseDBURL: @getFieldDBBaseDBURL(responseJSON.user)
              username: credentials.username,
              password: credentials.password,
              loggedInUser: responseJSON.user
            @save()
            credentials.name = credentials.username
            @authenticateFieldDBCorpusService credentials, taskId
          else
            Backbone.trigger 'authenticate:fail', responseJSON.userFriendlyErrors
            @authenticateAttemptDone taskId
        onerror: (responseJSON) =>
          Backbone.trigger 'authenticate:fail', responseJSON
          @authenticateAttemptDone taskId
        ontimeout: =>
          Backbone.trigger 'authenticate:fail', error: 'Request timed out'
          @authenticateAttemptDone taskId
      )

    authenticateFieldDBCorpusService: (credentials, taskId) ->
      BaseRelationalModel.cors.request(
        method: 'POST'
        timeout: 3000
        url: "#{@get('baseDBURL')}/_session"
        payload: credentials
        onload: (responseJSON) =>
          # TODO @jrwdunham: this responseJSON has a roles Array attribute which
          # references more corpora than I'm seeing from the `corpusteam`
          # request. Why the discrepancy?
          @authenticateAttemptDone taskId
          if responseJSON.ok
            @save
              loggedIn: true
              loggedInUserRoles: responseJSON.roles
            Backbone.trigger 'authenticate:success'
          else
            Backbone.trigger 'authenticate:fail', responseJSON
        onerror: (responseJSON) =>
          Backbone.trigger 'authenticate:fail', responseJSON
          @authenticateAttemptDone taskId
        ontimeout: =>
          Backbone.trigger 'authenticate:fail', error: 'Request timed out'
          @authenticateAttemptDone taskId
      )

    # WARN: DEPRECATED until I can figure out the issue detailed in the comment
    # below.
    # This is based on the FieldDB AngularJS Core source, i.e.,
    # https://github.com/OpenSourceFieldlinguistics/FieldDB/blob/master/\
    #   angular_client/modules/core/app/scripts/directives/\
    #   fielddb-authentication.js
    authenticateFieldDB: (credentials) ->
      credentials.serverCode = 'production' # debuggin
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'authenticating', taskId

      FieldDB.Database::BASE_AUTH_URL = @getURL()

      # ISSUE @cesine @jrwdunham: Dative can't know the DB_URL without first
      # receiving the response from calling `FieldDB.Database::login`. (Call
      # `@getFieldDBBaseDBURL user` on the returned user to get it.) However,
      # `FieldDB/api/corpus/Database.js` (lines 294-345) logs in to its default
      # DB_URL (https://localhost:6984) immediately after Auth Service
      # authentication succeeds. The request to get the metadata of a corpus,
      # however, uses http://localhost:5984, wich is from the `user.corpuses`
      # array. @jrwdunham corpora not be 'http://localhost:5984' but rather 'https://localhost:6984'
      # that was an error on the auth service that was never code-reviewed...
      #
      # fixed in https://github.com/OpenSourceFieldlinguistics/AuthenticationWebService/pull/35
      #
      #   FieldDB.Database::BASE_DB_URL = 'http://localhost:5984'

      FieldDB.Database::login(credentials).then(
        (user) =>
          try
            @save
              username: credentials.username,
              password: credentials.password,
              loggedIn: true
              loggedInUser: user
            Backbone.trigger 'authenticate:success'
          catch
            Backbone.trigger 'authenticate:fail',
              ['Authentication with the FieldDB server worked, but something',
                'went wrong with Dative.'].join(' ')
        ,
        (reason) ->
          Backbone.trigger 'authenticate:fail', reason
      ).catch(
        ->
          Backbone.trigger 'authenticate:fail',
            'FieldDB.Database::login triggered an error'
      ).done(
        =>
          @authenticateAttemptDone taskId
      )


    # Logout
    #=========================================================================

    logout: ->
      if @get('activeServer')?.get('type') is 'FieldDB'
        @logoutFieldDB()
      else
        @logoutOLD()

    logoutOLD: ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'logout', taskId
      BaseRelationalModel.cors.request(
        url: "#{@getURL()}/login/logout"
        method: 'GET'
        timeout: 3000
        onload: (responseJSON) =>
          @authenticateAttemptDone taskId
          if responseJSON.authenticated is false
            @save 'loggedIn', false
            Backbone.trigger 'logout:success'
          else
            Backbone.trigger 'logout:fail'
        onerror: (responseJSON) =>
          @authenticateAttemptDone taskId
          Backbone.trigger 'logout:fail'
        ontimeout: =>
          @authenticateAttemptDone taskId
          Backbone.trigger 'logout:fail', error: 'Request timed out'
      )

    logoutFieldDB: ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'logout', taskId
      FieldDB.Database::BASE_AUTH_URL = @getURL()
      FieldDB.Database::BASE_DB_URL = @getCorpusServerURL()
      FieldDB.Database::logout().then(
        (responseJSON) =>
          if responseJSON.ok is true
            @save 'loggedIn', false
            Backbone.trigger 'logout:success'
          else
            Backbone.trigger 'logout:fail',
              "server #{@getURL()} did not accept logout request."
        ,
        (reason) ->
          Backbone.trigger 'logout:fail', reason
      ).done(=> @authenticateAttemptDone taskId)


    # Check if logged in
    #=========================================================================

    # Check if we are already logged in.
    checkIfLoggedIn: ->
      if @get('activeServer')?.get('type') is 'FieldDB'
        @checkIfLoggedInFieldDB()
      else
        @checkIfLoggedInOLD()

    checkIfLoggedInOLD: ->
      taskId = @guid()
      Backbone.trigger('longTask:register', 'checking if already logged in',
        taskId)
      BaseRelationalModel.cors.request(
        url: "#{@getURL()}/speakers"
        timeout: 3000
        onload: (responseJSON) =>
          @authenticateAttemptDone(taskId)
          if utils.type(responseJSON) is 'array'
            @save 'loggedIn', true
            Backbone.trigger 'authenticate:success'
          else
            @save 'loggedIn', false
            Backbone.trigger 'authenticate:fail'
        onerror: (responseJSON) =>
          @save 'loggedIn', false
          Backbone.trigger 'authenticate:fail', responseJSON
          @authenticateAttemptDone(taskId)
        ontimeout: =>
          @save 'loggedIn', false
          Backbone.trigger 'authenticate:fail', error: 'Request timed out'
          @authenticateAttemptDone(taskId)
      )

    checkIfLoggedInFieldDB: ->
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
      ).done(=> @authenticateAttemptDone taskId)


    # Register a new user
    # =========================================================================

    # `RegisterDialogView` should never allow an OLD registration attempt.
    register: (params) ->
      if @get('activeServer')?.get('type') is 'FieldDB'
        @registerFieldDB params

    registerFieldDB: (params) ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'registering a new user', taskId

      params.authUrl = @getURL()
      # TODO @cesine: `appVersionWhenCreated`: should it be Dative current
      # version?
      # TODO deploy shell script should search-and-replace "dative-app-verson"
      # with the value from `bower.json`.
      params.appVersionWhenCreated = 'dative-app-version'

      BaseRelationalModel.cors.request(
        url: "#{@getURL()}/register"
        payload: params
        method: 'POST'
        timeout: 10000 # FieldDB auth can take some time to register a new user ...
        onload: (responseJSON) =>
          @authenticateAttemptDone taskId
          # TODO @cesine: what other kinds of responses to registration requests
          # can the auth service make?
          if responseJSON.user?
            user = responseJSON.user
            Backbone.trigger 'register:success', responseJSON
          else
            Backbone.trigger 'register:fail', responseJSON.userFriendlyErrors
        onerror: (responseJSON) =>
          @authenticateAttemptDone taskId
          Backbone.trigger 'register:fail', 'server responded with error'
        ontimeout: =>
          @authenticateAttemptDone taskId
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
        includeInJSON: ['id', 'name', 'type', 'url', 'serverCode', 'corpusServerURL']
        reverseRelation:
          key: 'applicationSettings'
      ,
        type: Backbone.HasOne
        key: 'activeServer'
        relatedModel: ServerModel
        includeInJSON: 'id'
      #,
      #  type: Backbone.HasMany
      #  key: 'fieldDBCorpora'
      #  relatedModel: CorpusModel
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
        corpusServerURL: null

      server2 =
        id: @guid()
        name: 'OLD Development'
        type: 'OLD'
        url: 'http://127.0.0.1:5000'
        serverCode: null
        corpusServerURL: null

      server3 =
        id: @guid()
        name: 'FieldDB'
        type: 'FieldDB'
        url: 'https://auth.lingsync.org'
        serverCode: 'production'
        corpusServerURL: null

      server4 =
        id: @guid()
        name: 'OLD'
        type: 'OLD'
        url: 'http://www.onlinelinguisticdatabase.org'
        serverCode: null
        corpusServerURL: null

      id: @guid()
      activeServer: server1.id
      loggedIn: false
      loggedInUser: null
      loggedInUserRoles: []
      baseDBURL: null
      username: ''
      password: '' # WARN: I don't like storing the password in localStorage, but FieldDB needs to send it on subsequent requests, so I'm persisting it for now ...
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

      activeJQueryUITheme: 'cupertino'
      jQueryUIThemes: [
        ['ui-lightness', 'UI lightness']
        ['ui-darkness', 'UI darkness']
        ['smoothness', 'Smoothness']
        ['start', 'Start']
        ['redmond', 'Redmond']
        ['sunny', 'Sunny']
        ['overcast', 'Overcast']
        ['le-frog', 'Le Frog']
        ['flick', 'Flick']
        ['pepper-grinder', 'Pepper Grinder']
        ['eggplant', 'Eggplant']
        ['dark-hive', 'Dark Hive']
        ['cupertino', 'Cupertino']
        ['south-street', 'South Street']
        ['blitzer', 'Blitzer']
        ['humanity', 'Humanity']
        ['hot-sneaks', 'Hot Sneaks']
        ['excite-bike', 'Excite Bike']
        ['vader', 'Vader']
        ['dot-luv', 'Dot Luv']
        ['mint-choc', 'Mint Choc']
        ['black-tie', 'Black Tie']
        ['trontastic', 'Trontastic']
        ['swanky-purse', 'Swanky Purse']
      ]

  # Backbone-relational requires this when using CoffeeScript
  ApplicationSettingsModel.setup()

