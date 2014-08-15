define [
  'underscore'
  'backbone'
  'models/base'
  'utils/utils'
], (_, Backbone, BaseModel, utils) ->

  # Application Settings
  # --------------------
  #
  # This should be persisted locally (localStorage or indexedDB)
  # and not saved to the server/web service.

  class ApplicationSettingsModel extends BaseModel

    # TODO: implement persistence to localStorage
    # It should be possible to use the Backbone localStorage adapter
    # (https://github.com/jeromegn/Backbone.localStorage)
    # just for one model (i.e., this model) and use REST (and indexedDB)
    # for other mdoels. This will involve overriding the sync method of
    # this model so that it references the Backbone.localStorage sync
    # function. I need to preserve Backbone's original sync function after
    # loading Backbone.localStorage (and Backbone.indexedDB) though ...
    # See http://stackoverflow.com/questions/5761349/backbone-js-able-to-do-rest-and-localstorage?lq=1
    # for ideas
    sync: ->
      console.log 'Sync'
      console.log 'Sync'
      console.log 'Sync'

    constructor: ->
      @listenTo Backbone, 'authenticate:login', @authenticate
      @listenTo Backbone, 'authenticate:logout', @logout
      if not Modernizr.localstorage
        throw new Error 'localStorage unavailable in this browser, please upgrade.'
      BaseModel.apply @, arguments

    # Attempt to authenticate with the passed-in credentials
    # TODO: encapsulate the LingSync authentication request.
    authenticate: (username, password) ->

      @cors(
        method: 'POST'
        url: "#{@getURL()}login/authenticate"
        payload: username: username, password: password
        onload: (responseJSON) =>
          if responseJSON.authenticated
            @set 'loggedIn', true
            console.log 'Successfully authenticated'
          else
            Backbone.trigger 'authenticate:fail', responseJSON
            console.log "Failed to authenticate:
              #{JSON.stringify(responseJSON)}"
        onerror: (responseJSON) ->
          Backbone.trigger 'authenticate:fail', responseJSON
          console.log 'Error when attempting to authenticate'
      )

    logout: ->

      @cors(
        url: "#{@getURL()}login/logout"
        onload: (responseJSON) =>
          if not responseJSON.authenticated
            @set 'loggedIn', false
            console.log 'Successfully logged out'
          else
            console.log 'Failed to log out :('
        onerror: (responseJSON) =>
          console.log 'Error when attempting to log out'
      )

    # Return our URL by combining serverURL and serverPort, if specified
    getURL: ->
      serverURL = @.get 'serverURL'
      serverPort = @.get 'serverPort'
      url = "#{serverURL}#{serverPort and ':' + serverPort or ''}/"

    # Check if we are already logged in by requesting the speakers collection.
    # (OLD-specific, somewhat arbitrary request to test for authentication.)
    checkIfLoggedIn: (url, port) ->
      @cors(
        url: "#{url}#{port and ':' + port or ''}/speakers"
        onload: (responseJSON) =>
          if utils.type(responseJSON) is 'array'
            console.log 'We are logged in'
            @set 'loggedIn', true
          else
            console.log 'We are NOT logged in'
            @set 'loggedIn', false
        onerror: (responseJSON) =>
          console.log 'We are NOT logged in (error in getting speakers)'
          @set 'loggedIn', false
      )

    defaults: ->

      defaults =
        # URL of the server where the data are stored (LingSync corpus or OLD web
        # service)
        #serverURL: "http://www.onlinelinguisticdatabase.org/" # ... as an example
        serverURL: 'http://127.0.0.1'

        serverPort: '5000' # default: null

        loggedIn: false
        username: null
        password: null

        # Right now I'm focusing on server-side persistence to an OLD RESTful web
        # service. The next step will be persistence to a LingSync corpus, then
        # client-side (indexedDB) persistence, and, finally, progressively
        # improved dual-layer persistence (i.e., client and server). An
        # interesting possibility would be to enable Dative to provide a single
        # interface to multiple web services, e.g., multiple OLD web services
        # and multiple LingSync corpora...
        persistenceType: "server" # "server", "client", or "dual"

        # Schema type will become relevant later on ...
        schemaType: "relational" # "relational" or "nosql"

      defaults.loggedIn = @checkIfLoggedIn defaults.serverURL, defaults.serverPort

      defaults

