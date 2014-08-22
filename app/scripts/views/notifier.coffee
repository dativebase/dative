define [
  'jquery'
  'lodash'
  'backbone'
  'templates'
  'views/base'
], ($, _, Backbone, JST, BaseView) ->

  # Notifier
  # ---------------
  #
  # Notifies user when things happen.

  class NotifierView extends BaseView

    template: JST['app/scripts/templates/notifier.ejs']

    initialize: ->
      @messages = []
      @listenTo Backbone, 'authenticate:fail', @authenticateFail
      @listenTo Backbone, 'authenticate:success', @authenticateSuccess
      @listenTo Backbone, 'logout:fail', @logoutFail
      @listenTo Backbone, 'logout:success', @logoutSuccess

    render: ->
      @$el.html(@template(messages: @messages)).fadeIn(
        complete: =>
          duration = @messages.length * 2000
          @messages = []
          @$el.fadeOut duration
      )

    authenticateFail: (errorObj) ->
      @messages.push "Failed to authenticate: #{errorObj.error}"
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

