define [
  'underscore'
  'backbone'
  './base-relational'
  './../utils/utils'
], (_, Backbone, BaseRelationalModel, utils) ->

  # Server Model
  # ------------

  class ServerModel extends BaseRelationalModel

    initialize: ->
      console.log 'ServerModel initialized'
      #@on 'all', @tmp

    tmp: (event) ->
      console.log "#{event} was triggered on ServerModel"

    idAttribute: 'id'

    defaults: ->
      name: ''
      type: 'OLD' # 'OLD' or 'FieldDB'
      url: '' # must be unique
      corpora: [] # array of objects
      corpus: '' # object

  ServerModel.setup()

