define [
  'underscore'
  'backbone'
  './base'
  './../utils/utils'
], (_, Backbone, BaseModel, utils) ->

  # Server Model
  # ------------

  class ServerModel extends BaseModel

    idAttribute: 'id'

    defaults: ->
      id: @guid()
      name: ''
      type: 'OLD' # 'OLD' or 'FieldDB'
      url: '' # must be unique
      serverCode: '' # FieldDB-specific; see `model/application-settings` for the list.
      corpusServerURL: null

