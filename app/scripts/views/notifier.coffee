define [
  'jquery'
  'lodash'
  'backbone'
  './base'
  './../templates/notifier'
  './../utils/utils'
], ($, _, Backbone, BaseView, notifierTemplate, utils) ->

  # Notifier
  # ---------------
  #
  # Notifies user when things happen.

  class NotifierView extends BaseView

    template: notifierTemplate

    initialize: (@applicationSettings) ->
      @messages = []
      @listenTo Backbone, 'authenticate:fail', @authenticateFail
      @listenTo Backbone, 'authenticate:success', @authenticateSuccess
      @listenTo Backbone, 'logout:fail', @logoutFail
      @listenTo Backbone, 'logout:success', @logoutSuccess
      @listenTo Backbone, 'register:fail', @registerFail
      @listenTo Backbone, 'register:success', @registerSuccess

    render: ->
      @$el.html(@template(messages: @messages)).fadeIn(
        complete: =>
          duration = @messages.length * 4000
          @messages = []
          @$el.fadeOut duration
      )

    registerFail: (reason) ->
      message = "Could not register a new user. #{reason}"
      @messages.push message
      @render()

    registerSuccess: ->
      @messages.push 'Registration succeeded.'
      @render()

    authenticateFail: (errorObj) ->
      # TODO @jrwdunham: simplify the messaging system so that a "reason" is always
      # returned and not sometimes a reason string and sometimes an object.
      # CouchDB returns {error: "unauthorized", reason: "Name or password is
      #   incorrect."}
      # OLD returns {error: "The username and password provided are not valid."}
      message = 'Failed to authenticate'
      if errorObj
        if @applicationSettings.get('activeServer')?.get('type') is 'OLD'
          if errorObj.error
            message = "#{message}: #{errorObj.error}."
          else
            message = "#{message}: reason unknown."
        else
          if utils.type(errorObj) is 'object' # FieldDB API returns string, not object (always?)
            message = "#{message}: reason unknown."
          else
            message = "#{message}: #{errorObj}."
      else
        message = "#{message}."
      @messages.push message
      @render()

    authenticateSuccess: ->
      @messages.push 'Logged in'
      @render()

    logoutFail: ->
      @messages.push 'Failed to logout'
      @render()

    logoutSuccess: ->
      @messages.push 'Logged out'
      @render()

