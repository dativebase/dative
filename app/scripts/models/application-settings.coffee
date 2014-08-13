define [
  'underscore'
  'backbone'
  'models/base'
], (_, Backbone, BaseModel) ->

  # Application Settings
  # --------------------
  #
  # This should be persisted locally (localStorage or indexedDB)
  # and not saved to the server/web service.

  class ApplicationSettingsModel extends BaseModel

    constructor: ->
      @listenTo Backbone, 'authenticate', @authenticate
      BaseModel.apply @, arguments

    # Attempt to authenticate with the passed-in credentials
    # TODO: encapsulate the LingSync authentication request.
    authenticate: (username, password) ->

      serverURL = @.get 'serverURL'
      serverPort = @.get 'serverPort'
      url = "#{serverURL}#{serverPort and ':' + serverPort or
        ''}/login/authenticate"
      method = 'POST'
      payload = username: username, password: password

      # Abtraction around CORS requests, defined on BaseModel
      @cors(
        method: method,
        url: url,
        payload: payload
        onload: (responseJSON) =>
          if responseJSON.authenticated
            @set 'loggedIn', true
            console.log 'Successfully authenticated'
          else
            console.log "Failed to authenticate:
              #{JSON.stringify(responseJSON)}"
        onerror: (responseJSON) ->
          console.log 'Error when attempting to authenticate'
      )

    defaults: ->

      # URL of the server where the data are stored (LingSync corpus or OLD web
      # service)
      #serverURL: "http://www.onlinelinguisticdatabase.org/" # ... as an example
      serverURL: 'http://127.0.0.1'

      serverPort: '5000' # default: null

      loggedIn: false

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

