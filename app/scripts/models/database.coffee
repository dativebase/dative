define [
    'underscore',
    'backbone',
  ], (_, Backbone) ->

    database =
      id: "fielddb-database"
      description: "IndexedDB database to hold FieldDB data locally in the web
        browser"
      nolog: true # tell backbone-indexeddb to shut up
      migrations: [
        version: 1
        migrate: (transaction, next) ->
          store = transaction.db.createObjectStore "forms"
          store.createIndex "transcriptionIndex", "transcription", {unique: false}
          next()
      ]

