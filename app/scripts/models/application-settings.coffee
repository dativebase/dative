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

    save: ->
      localStorage.setItem 'dativeApplicationSettings',
        JSON.stringify(@attributes)

    urlChanged: ->
      if 'serverURL' of @changed or 'serverPort' of @changed
        @checkIfLoggedIn()

    fetch: ->
      if localStorage.dativeApplicationSettings
        @set JSON.parse(localStorage.dativeApplicationSettings)

    constructor: ->
      @listenTo Backbone, 'authenticate:login', @authenticate
      @listenTo Backbone, 'authenticate:logout', @logout
      @on 'change', @urlChanged
      if not Modernizr.localstorage
        throw new Error 'localStorage unavailable in this browser, please upgrade.'
      super

    # Attempt to authenticate with the passed-in credentials
    # TODO: encapsulate the LingSync authentication request.
    authenticate: (username, password) ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'authenticating', taskId
      @cors(
        method: 'POST'
        url: "#{@getURL()}login/authenticate"
        timeout: 3000
        payload: username: username, password: password
        onload: (responseJSON) =>
          Backbone.trigger 'longTask:deregister', taskId
          Backbone.trigger 'authenticate:end'
          if responseJSON.authenticated
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
      @cors(
        url: "#{@getURL()}login/logout"
        timeout: 3000
        onload: (responseJSON) =>
          Backbone.trigger 'authenticate:end'
          Backbone.trigger 'longTask:deregister', taskId
          if not responseJSON.authenticated
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
    getURL: ->
      serverURL = @get 'serverURL'
      serverPort = @get 'serverPort'
      url = "#{serverURL}#{serverPort and ':' + serverPort or ''}/"

    # Check if we are already logged in by requesting the speakers collection.
    # (NOTE: this is an OLD-specific, somewhat arbitrary means of testing for
    # authentication.)
    checkIfLoggedIn: ->
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'checking if already logged in', taskId
      url = @get 'serverURL'
      port = @get 'serverPort'
      @cors(
        url: "#{url}#{port and ':' + port or ''}/speakers"
        timeout: 3000
        onload: (responseJSON) =>
          Backbone.trigger 'longTask:deregister', taskId
          Backbone.trigger 'authenticate:end'
          if utils.type(responseJSON) is 'array'
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

      # URL of the server where the data are stored (LingSync corpus or OLD web
      # service)
      #serverURL: "http://www.onlinelinguisticdatabase.org/" # ... as an example
      serverURL: 'http://127.0.0.1'

      serverPort: '5000' # default: null

      loggedIn: false
      username: ''

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

