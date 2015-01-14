define [
  'jquery',
  'backbone'
], ($, Backbone) ->
  class Workspace extends Backbone.Router
    routes:
      '*filter': 'setFilter'
      'help': 'help'

    setFilter: ->
      #console.log 'setFilter called in js/routers/router.js'
      true

    help: ->
      console.log "help!"
      true

