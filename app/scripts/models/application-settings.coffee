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
      @on 'change', @_urlChanged
      if not Modernizr.localstorage
        throw new Error 'localStorage unavailable in this browser, please upgrade.'
      super

    save: ->
      localStorage.setItem 'dativeApplicationSettings',
        JSON.stringify(@attributes)

    fetch: ->
      if localStorage.getItem 'dativeApplicationSettings'
        @set JSON.parse(localStorage.getItem('dativeApplicationSettings'))

    _urlChanged: ->
      if @hasChanged('serverURL') or @hasChanged('serverPort')
        @checkIfLoggedIn()

    # Attempt to authenticate with the passed-in credentials
    # TODO: responseJSON from CouchDB also returns an array of roles; use it.
    authenticate: (username, password) ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'authenticating', taskId

      url = "#{@_getURL()}login/authenticate"
      payload = username: username, password: password
      success = (r) -> r.authenticated is true
      if @get('serverType') is 'LingSync'
        url = "#{@_getURL()}_session"
        payload = name: username, password: password
        success = (r) -> r.ok is true

      @cors(
        method: 'POST'
        timeout: 3000
        url: url
        payload: payload
        onload: (responseJSON) =>
          Backbone.trigger 'longTask:deregister', taskId
          Backbone.trigger 'authenticate:end'
          if success(responseJSON)
            @set username: username, loggedIn: true
            Backbone.trigger 'authenticate:success'
          else
            Backbone.trigger 'authenticate:fail', responseJSON
        onerror: (responseJSON) ->
          Backbone.trigger 'authenticate:fail', responseJSON
          Backbone.trigger 'longTask:deregister', taskId
          Backbone.trigger 'authenticate:end'
        ontimeout: ->
          Backbone.trigger 'authenticate:fail', error: 'Request timed out'
          Backbone.trigger 'longTask:deregister', taskId
          Backbone.trigger 'authenticate:end'
      )

    logout: ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'logout', taskId

      url = "#{@_getURL()}login/logout"
      method = 'GET'
      logoutBoolean = 'authenticated'
      success = (r) -> r.authenticated is false
      if @get('serverType') is 'LingSync'
        url = "#{@_getURL()}_session"
        method = 'DELETE'
        success = (r) -> r.ok is true

      @cors(
        url: url
        method: method
        timeout: 3000
        onload: (responseJSON) =>
          Backbone.trigger 'authenticate:end'
          Backbone.trigger 'longTask:deregister', taskId
          if success(responseJSON)
            @set 'loggedIn', false
            Backbone.trigger 'logout:success'
          else
            Backbone.trigger 'logout:fail'
        onerror: (responseJSON) =>
          Backbone.trigger 'authenticate:end'
          Backbone.trigger 'longTask:deregister', taskId
          Backbone.trigger 'logout:fail'
        ontimeout: ->
          Backbone.trigger 'logout:fail', error: 'Request timed out'
          Backbone.trigger 'longTask:deregister', taskId
          Backbone.trigger 'authenticate:end'
      )

    # Return our URL by combining serverURL and serverPort, if specified
    _getURL: ->
      serverURL = @get 'serverURL'
      serverPort = @get 'serverPort'
      "#{serverURL}#{serverPort and ':' + serverPort or ''}/"

    # Check if we are already logged in.
    checkIfLoggedIn: ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'checking if already logged in', taskId

      if @get('serverType') is 'old'
        # TODO: this shouldn't be a speakers request: this should return
        # username of logged in user. I need to change the OLD API in that case ...
        url = "#{@_getURL()}speakers"
        success = (r) -> utils.type(r) is 'array'
      else
        url = "#{@_getURL()}_session"
        success = (r) -> r?.ok is true

      @cors(
        url: url
        timeout: 3000
        onload: (responseJSON) =>
          Backbone.trigger 'longTask:deregister', taskId
          Backbone.trigger 'authenticate:end'
          if success(responseJSON)
            @set 'loggedIn', true
            Backbone.trigger 'authenticate:success'
          else
            @set 'loggedIn', false
            Backbone.trigger 'authenticate:fail'
        onerror: (responseJSON) =>
          @set 'loggedIn', false
          Backbone.trigger 'authenticate:fail', responseJSON
          Backbone.trigger 'longTask:deregister', taskId
          Backbone.trigger 'authenticate:end'
        ontimeout: =>
          @set 'loggedIn', false
          Backbone.trigger 'authenticate:fail', error: 'Request timed out'
          Backbone.trigger 'longTask:deregister', taskId
          Backbone.trigger 'authenticate:end'
      )

    defaults: ->

      serverType: 'LingSync' # other option 'OLD'

      # URL of the server where the data are stored (LingSync corpus or OLD web
      # service)
      #serverURL: "http://www.onlinelinguisticdatabase.org/" # ... as an example
      serverURL: 'http://127.0.0.1'

      serverPort: '5000' # default: null

      loggedIn: false
      username: ''

      # corpora: ['corpus 1', 'corpus 2'] # corpora I have access to.
      corpora: [] # corpora I have access to.
      corpus: null # corpora I most recently accessed.

      # Note: the following attributes are not currently being used (displayed)

      # Right now I'm focusing on server-side persistence to an OLD RESTful web
      # service. The next step will be persistence to a LingSync corpus, then
      # client-side (indexedDB) persistence, and, finally, progressively
      # improved dual-layer persistence (i.e., client and server). An
      # interesting possibility would be to enable Dative to provide a single
      # simultaneous interface to multiple web services, e.g., multiple OLD web
      # services and multiple LingSync corpora...
      persistenceType: "server" # "server", "client", or "dual"

      # Schema type will become relevant later on ...
      schemaType: "relational" # "relational" or "nosql"

      itemsPerPage: 10

