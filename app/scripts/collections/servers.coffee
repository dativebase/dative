define [
    'backbone',
    './../models/server'
  ], (Backbone, ServerModel) ->

  # Servers Collection
  # ------------------

  class ServersCollection extends Backbone.Collection

    model: ServerModel

    initialize: ->
      @on 'removeme', @_removeModel

    _removeModel: (model) ->
      @remove model

