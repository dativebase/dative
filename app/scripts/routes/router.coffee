define [
  'jquery',
  'backbone'
  './../utils/utils'
], ($, Backbone, utils) ->

  class Workspace extends Backbone.Router

    initialize: (options) ->
      @mainMenuView = options.mainMenuView
      @resources = options.resources
      @createResourceRoutes()

    createResourceRoutes: ->
      for resourceName of @resources
        do =>
          resourcePlural = utils.pluralize resourceName
          resourcePluCap = utils.capitalize resourcePlural
          route = utils.camel2hyphen resourcePlural
          methodName = "request#{resourcePluCap}Browse"
          eventName = "request:#{resourcePlural}Browse"
          @[methodName] = => @mainMenuView.trigger eventName
          @route route, methodName

    routes:
      'home': 'home'
      'login': 'openLoginDialogBox'
      'register': 'openRegisterDialogBox'

