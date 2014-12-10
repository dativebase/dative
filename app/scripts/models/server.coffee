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
      type: 'OLD' # 'OLD' or 'FieldDB'
      url: '' # must be unique
      corpora: [] # array of objects
      corpus: '' # object

  # Backbone-relational + CoffeeScript requirement:
  ServerModel.setup()

