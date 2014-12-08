define [
    'backbone',
    './../models/server'
  ], (Backbone, ServerModel) ->

  # Servers Collection
  # ------------------

  class ServersCollection extends Backbone.Collection

    model: ServerModel

    initialize: ->
      #@on 'all', @tmp
      @on 'destroy', @_removeModel

    tmp: (event) ->
      console.log arguments
      console.log "#{event} was triggered on servers collection"

    sync: (method, collection, options) ->
      console.log 'you, my friend are trying to sync a servers collection.'

    _removeModel: (model, collection, options) ->
      console.log 'in servers collection, model destroy event triggered.'
      #@remove model

