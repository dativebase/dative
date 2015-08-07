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
          resourceCapitalized = utils.capitalize resourceName

          route1 = utils.camel2hyphen resourcePlural
          methodName1 = "request#{resourcePluCap}Browse"
          eventName1 = "request:#{resourcePlural}Browse"
          @[methodName1] = => @mainMenuView.trigger eventName1
          @route route1, methodName1

          route2 = "#{utils.camel2hyphen resourceName}/:resourceId"
          methodName2 = "request#{resourceCapitalized}View"
          eventName2 = "request:#{resourceCapitalized}View"
          @[methodName2] = (resourceId) =>
            Backbone.trigger eventName2, resourceId
          @route route2, methodName2

    routes:
      'home': 'home'
      'login': 'openLoginDialogBox'
      'register': 'openRegisterDialogBox'

