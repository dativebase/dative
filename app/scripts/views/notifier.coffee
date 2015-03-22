define [
  './base'
  './notification'
  './../templates/notifier'
], (BaseView, NotificationView, notifierTemplate) ->

  # Notifier
  # --------
  #
  # Handler for creating, displaying, hiding, and destroying notifications.

  class NotifierView extends BaseView

    template: notifierTemplate

    initialize: ->

      @notifications = []
      @maxNotifications = 3

      @listenTo Backbone, 'authenticate:fail', @authenticateFail
      @listenTo Backbone, 'authenticate:success', @authenticateSuccess

      @listenTo Backbone, 'logout:fail', @logoutFail
      @listenTo Backbone, 'logout:success', @logoutSuccess

      @listenTo Backbone, 'register:fail', @registerFail
      @listenTo Backbone, 'register:success', @registerSuccess

      @listenTo Backbone, 'addOLDFormFail', @addOLDFormFail
      @listenTo Backbone, 'addOLDFormSuccess', @addOLDFormSuccess

    render: ->
      @$el.html @template()
      @

    renderNotification: (notification) ->
      @listenTo notification, 'notifierRendered', @closeOldNotifications
      @listenTo notification, 'destroySelf', @closeNotification
      @$('.notifications-container').append notification.render().el
      @rendered notification
      @notifications.push notification

    closeOldNotifications: ->
      while @notifications.length > @maxNotifications
        oldNotification = @notifications.shift()
        @closeNotification oldNotification

    closeNotification: (notification) ->
      notification.$el.slideUp()
      notification.close()
      @closed notification

    addOLDFormSuccess: (formModel) ->
      notification = new NotificationView
        title: 'Form created'
        content: "You have successfully created a new form. Its id is
          #{formModel.get 'id'}."
      @renderNotification notification

    addOLDFormFail: (error) ->
      if error
        content = "Your form creation request was unsuccessful. #{error}"
      else
        content = "Your form creation request was unsuccessful. See the error
          message(s) next to the input fields."
      notification = new NotificationView
        title: 'Form creation failed'
        content: content
        type: 'error'
      @renderNotification notification

    registerFail: (reason) ->
      notification = new NotificationView
        title: 'Register failed'
        content: "Your attempt to register was unsuccessful. #{reason}"
        type: 'error'
      @renderNotification notification

    registerSuccess: ->
      notification = new NotificationView
        title: 'Registered'
        content: 'You have successfully created a new account'
      @renderNotification notification

    authenticateFail: (errorObj) ->
      notification = new NotificationView
        title: 'Login failed'
        content: @getAuthenticateFailContent errorObj
        type: 'error'
      @renderNotification notification

    authenticateSuccess: ->
      notification = new NotificationView
        title: 'Logged in'
        content: 'You have successfully logged in.'
      @renderNotification notification

    logoutFail: ->
      notification = new NotificationView
        title: 'Logout failed'
        content: 'Your attempt to log out was unsuccessful.'
        type: 'error'
      @renderNotification notification

    logoutSuccess: ->
      notification = new NotificationView
        title: 'Logged out'
        content: 'You have successfully logged out.'
      @renderNotification notification

    getAuthenticateFailContent: (errorObj) ->
      contentPrefix = 'Yor attempt to log in was unsuccessful.'
      if errorObj
        if @getActiveServerType() is 'OLD'
          if errorObj.error
            "#{contentPrefix} #{errorObj.error}"
          else
            contentPrefix
        else
          if @utils.type(errorObj) is 'object' # FieldDB API returns string, not object (always?)
            if errorObj.reason
              "#{contentPrefix} #{errorObj.reason}"
            else
              contentPrefix
          else
            "#{contentPrefix} #{errorObj}"
      else
        contentPrefix

