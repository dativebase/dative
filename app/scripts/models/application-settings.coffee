define [
    'underscore'
    'backbone'
  ], (_, Backbone) ->

    # Application Settings
    # --------------------

    schemaType: "relational" # "relational" or "nosql"
    persistenceType: "server" # "server", "client", or "dual"
    serverURL: "http://www.onlinelinguisticdatabase.org/" # ... as an example

