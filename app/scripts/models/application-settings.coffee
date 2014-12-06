define [
  'underscore'
  'backbone'
  './base'
  './../utils/utils'
], (_, Backbone, BaseModel, utils) ->

  # Application Settings
  # --------------------
  #
  # The application settings are persisted *very simply* using HTML's
  # localStorage. (Got frustrated with Backbone.LocalStorage, and, anyways,
  # the overhead seems unnecessary.)

  class ApplicationSettingsModel extends BaseModel

    constructor: ->
      @listenTo Backbone, 'authenticate:login', @authenticate
      @listenTo Backbone, 'authenticate:logout', @logout
      @listenTo Backbone, 'authenticate:register', @register
      @on 'change', @_urlChanged
      if not Modernizr.localstorage
        throw new Error 'localStorage unavailable in this browser, please upgrade.'
      super

    save: ->
      if arguments.length
        @set.apply @, arguments
      localStorage.setItem 'dativeApplicationSettings',
        JSON.stringify(@attributes)

    fetch: ->
      if localStorage.getItem 'dativeApplicationSettings'
        @set JSON.parse(localStorage.getItem('dativeApplicationSettings'))

    _urlChanged: ->
      if @hasChanged('activeServer') or @hasChanged('servers')
        @checkIfLoggedIn()

    _getURL: ->
      @get 'activeServer'

    # Return our URL by combining serverURL and serverPort, if specified
    # WARN: deprecated.
    __getURL: ->
      serverURL = @get 'serverURL'
      serverPort = @get 'serverPort'
      "#{serverURL}#{serverPort and ':' + serverPort or ''}/"

    _authenticateAttemptDone: (taskId) ->
      Backbone.trigger 'longTask:deregister', taskId
      Backbone.trigger 'authenticate:end'


    # Login (a.k.a. authenticate)
    #=========================================================================

    # Attempt to authenticate with the passed-in credentials
    authenticate: (username, password) ->
      if @get('activeServer').type is 'FieldDB'
        @_authenticateFieldDB username: username, password: password
      else
        @_authenticateOLD username: username, password: password

    _authenticateOLD: (credentials) ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'authenticating', taskId
      @cors(
        method: 'POST'
        timeout: 3000
        url: "#{@_getURL()}login/authenticate"
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
      url = @_getURL()
      url = url.substring(-1, url.length - 1)
      FieldDB.Database::BASE_AUTH_URL = url
      FieldDB.Database::login(credentials).then(
        (user) =>
          # TODO: insert a test on the `user` object here.
          @save username: credentials.username, loggedIn: true
          Backbone.trigger 'authenticate:success'
          user = new FieldDB.User(user)
          # TODO: store the returned user somewhere
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
      if @get('activeServer').type is 'FieldDB'
        @_logoutFieldDB()
      else
        @_logoutOLD()

    _logoutOLD: ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'logout', taskId
      @cors(
        url: "#{@_getURL()}login/logout"
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
      FieldDB.Database::logout().then(
        (responseJSON) =>
          if responseJSON.ok is true
            @save 'loggedIn', false
            Backbone.trigger 'logout:success'
          else
            Backbone.trigger 'logout:fail'
        ,
        (reason) ->
          Backbone.trigger 'logout:fail', reason
      ).done(=> @_authenticateAttemptDone taskId)


    # Check if logged in
    #=========================================================================

    # Check if we are already logged in.
    checkIfLoggedIn: ->
      #@fetch()
      if @get('activeServer').type is 'FieldDB'
        @_checkIfLoggedInFieldDB()
      else
        @_checkIfLoggedInOLD()

    _checkIfLoggedInOLD: ->
      taskId = @guid()
      Backbone.trigger('longTask:register', 'checking if already logged in',
        taskId)
      @cors(
        url: "#{@_getURL()}speakers"
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
    #=========================================================================

    register: ->
      console.log 'you want to register a new user'


    # Defaults
    #=========================================================================

    defaults: ->

      activeServer: 'http://127.0.0.1:5000'
      loggedIn: false
      username: ''

      servers: [
          name: 'OLD Development Server'
          type: 'OLD'
          url: 'http://127.0.0.1:5000'
          corpora: []
          corpus: null
        ,
          name: 'FieldDB Development Server 1'
          type: 'FieldDB'
          url: 'https://localhost:3183'
          corpora: []
          corpus: null
        ,
          name: 'FieldDB Development Server 2'
          type: 'FieldDB'
          url: 'https://localhost:3181'
          corpora: []
          corpus: null
      ]

      serverTypes: ['FieldDB', 'OLD']

      # Note: the following attributes are not currently being used (displayed)

      # Right now I'm focusing on server-side persistence to an OLD RESTful web
      # service. The next step will be persistence to a FieldDB corpus, then
      # client-side (indexedDB) persistence, and, finally, progressively
      # improved dual-layer persistence (i.e., client and server). An
      # interesting possibility would be to enable Dative to provide a single
      # simultaneous interface to multiple web services, e.g., multiple OLD web
      # services and multiple FieldDB corpora...
      persistenceType: "server" # "server", "client", or "dual"

      # Schema type will become relevant later on ...
      schemaType: "relational" # "relational" or "nosql"

      itemsPerPage: 10

