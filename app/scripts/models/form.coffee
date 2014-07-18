define [
    'underscore'
    'backbone'
    './database'
    'backboneindexeddb'
  ], (_, Backbone, database) ->

    # Form Model
    # ----------
    #
    # Initially this is a relational dual storage (indexddb, REST)
    # OLD-compatible model. Hopefully, a Backbone model that is
    # LingSync-compatible can be created by modifying the LingSynch
    # Chrome App.

    class FormModel extends Backbone.Model

      url: ''
      database: database
      storeName: 'forms'

      defaults:
        transcription: ''
        morphemeBreak: ''
        morphemeGloss: ''
        translation: ''
        storageType: "local"
        schemaType: "relational"
        storeName: "form"

      validate: (attrs, options) ->

      parse: (response, options) ->
        response
