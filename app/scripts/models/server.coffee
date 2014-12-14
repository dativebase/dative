define [
  'underscore'
  'backbone'
  './base-relational'
  './../utils/utils'
], (_, Backbone, BaseRelationalModel, utils) ->

  # Server Model
  # ------------

  class ServerModel extends BaseRelationalModel

    idAttribute: 'id'

    defaults: ->
      id: @guid()
      name: ''
      type: 'FieldDB' # 'OLD' or 'FieldDB'
      url: '' # must be unique
      serverCode: 'production' # FieldDB-specific; see `model/application-settings` for the list.
      corpora: [] # array of objects
      corpus: '' # object

  # Backbone-relational + CoffeeScript requirement:
  ServerModel.setup()

