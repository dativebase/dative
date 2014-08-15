define [
  'jquery'
  'lodash'
  'backbone'
  'templates'
  'views/base'
], ($, _, Backbone, JST, BaseView) ->

  class LoginDialogView extends BaseView

    # Appended to the body since it's a dialog box
    el: 'body'

    template: JST['app/scripts/templates/login-dialog.ejs']

    initialize: ->
      @listenTo Backbone, 'authenticate:fail', @authenticateFail

    # OLD server responds with validation errors as well as authentication
    # errors. Authentication form should handle as much validation as possible,
    # preventing a request to the server when data are invalid.
    authenticateFail: (failObject) ->
      console.log 'in login dialog view'
      console.log 'authenticate fail'
      console.log failObject

    events:
      'click #old-login-request-button': 'login'
      #'click .old-login-dialog': 'login'

    render: ->
      console.log 'in render'
      @$el.append @template()
      @_dialogify()

    # Transform the login dialog HTML to a jQueryUI dialog box.
    _dialogify: ->

      @$el.find('.old-login-dialog input').css('border-color',
        LoginDialogView.jQueryUIColors.defBo)
      @$('.old-login-dialog').dialog(
          buttons: [
              text: 'Forgot password'
              click: @openForgotPasswordDialogBox
            ,
              text: 'Logout'
              click: =>
                #@close()
                @logout()
            ,
              text: 'Login'
              click: =>
                @login()
          ]
          dialogClass: 'old-login-dialog-widget'
          title: 'Login'
          width: 400
          open: =>
            @$('.old-login-dialog-widget button').each(->
              $(this).attr('tabindex', 1))
            @$('.old-login-dialog-widget span.old-login-failed').text('').hide()
          beforeClose: =>
            @cleanUpLoginDialogBox(clearFields: true, removeFocus: true)
          autoOpen: false
        )

      # Bind the Enter key to the "Login" button of the login dialog box
      @$('.old-login-dialog-widget input')
        .bind('keydown.loginWithEnter', (event) ->
          console.log 'LOGIN DIALOG IS LISTENING TO THAT RETURN'
          if event.which is 13
            event.stopImmediatePropagation()
            event.stopPropagation()
            $('.old-login-dialog-widget button').get(-1).click())

      # Render the "Login" button with the active display signifying to the user
      #  that the Return key submits the login form
      loginButton = @$(@$('.old-login-dialog-widget button').get(-1))
      loginButton.addClass('ui-state-active')

      @wrappedDialogBox = @$('.old-login-dialog')

    open: ->
      #@$('.old-login-dialog').dialog 'open'
      console.log 'in open method of LoginDialog'
      @wrappedDialogBox.dialog 'open'

    close: ->
      console.log 'in close method of LoginDialog'
      @wrappedDialogBox.dialog 'close'

    isOpen: ->
      @wrappedDialogBox.dialog 'isOpen'

    # Clean Up Login Dialog Box -- remove validation error widgets, unbind shortcuts
    cleanUpLoginDialogBox: (options) ->

      options = options or {}

      # Clear the input fields, if requested
      if options.clearFields
        @$('.old-login-dialog-widget input').val('')

      # Remove focus, if requested
      if options.removeFocus
        @$('.old-login-dialog-widget input').blur()

      # Re-enable the Login button and give it ui-state-active
      $(@$('.old-login-dialog-widget button').get(-1)).attr('disabled', false)
        .addClass('ui-state-active')

      # Remove any validation error icons and explain widgets
      @$('.old-val-err-widget, .old-explanation').remove()

      # Remove any invalid credentials notifications
      @$('.old-login-dialog-widget span.old-login-failed').text('').hide()

      # Restore the default border color of the input fields
      @$('.old-login-dialog-widget input')
        .css('border-color', LoginDialogView.jQueryUIColors.defBo)

    # Let the application settings model handle the authentication attempt
    login: ->
      console.log 'in login method of login dialog'

      username = @wrappedDialogBox.find('input[name=username]').val()
      password = @wrappedDialogBox.find('input[name=password]').val()

      # Trigger a global authenticate event that the ApplicationSettingsModel
      # will handle...
      Backbone.trigger 'authenticate:login', username, password

    logout: ->

      Backbone.trigger 'authenticate:logout'

    openForgotPasswordDialogBox: ->
      console.log 'You want to display the forgot password dialog.'

