define [
    'lodash',
    'backbone',
    '../models/form'
    '../models/database'
    'backboneindexeddb'
  ], (_, Backbone, FormModel, database) ->

    class FormsCollection extends Backbone.Collection

      database: database
      storeName: 'forms'
      model: FormModel

