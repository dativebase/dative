define [
  'jquery'
  'lodash'
  'backbone'
  'templates'
  'views/base'
], ($, _, Backbone, JST, BaseView) ->

  # LoginDialogView
  # ---------------
  #
  # This is a dialog box for authentication, i.e., loggin in, out, and
  # requesting a new password. It is a draggable box created using jQueryUI's
  # .dialog()

  class LoginDialogView extends BaseView

    # Appended to the body since it's a dialog box
    el: 'body'

    template: JST['app/scripts/templates/login-dialog.ejs']

    initialize: ->
      @listenTo Backbone, 'authenticate:fail', @authenticateFail
      @listenTo Backbone, 'authenticate:end', @authenticateEnd
      @listenTo Backbone, 'authenticate:success', @authenticateSuccess
      @listenTo @model, 'change:loggedIn', @disableButtons

    disableButtons: ->
      if @model.get 'loggedIn'
        @$('#login').button 'disable'
        @$('#logout').button 'enable'
        @$('#forgot-password').button 'disable'
        @$('#username').prop 'disabled', true
        @$('#password').prop 'disabled', true
      else
        @$('#login').button 'enable'
        @$('#logout').button 'disable'
        @$('#forgot-password').button 'enable'
        @$('#username').prop 'disabled', false
        @$('#password').prop 'disabled', false
        @$('#username').focus()

    # OLD server responds with validation errors as well as authentication
    # errors. Authentication form should handle as much validation as possible,
    # preventing a request to the server when data are invalid.
    authenticateFail: (failObject) ->

    authenticateSuccess: ->
      @close()

    authenticateEnd: ->
      @disableButtons()

    events:
      'click #old-login-request-button': 'login'
      'keyup #username': 'validate'
      'keyup #password': 'validate'
      'keydown #username': 'loginWithEnter'
      'keydown #password': 'loginWithEnter'

    render: ->
      @$el.append @template()
      @_dialogify()
      @disableButtons()

    # Transform the login dialog HTML to a jQueryUI dialog box.
    _dialogify: ->

      @$('.old-login-dialog input').css('border-color',
        LoginDialogView.jQueryUIColors.defBo)
      @$('.old-login-dialog').dialog(
          buttons: [
              text: 'Forgot password'
              click: @openForgotPasswordDialogBox
              id: 'forgot-password'
            ,
              text: 'Logout'
              click: =>
                @logout()
              id: 'logout'
            ,
              text: 'Login'
              click: =>
                @login()
              id: 'login'
          ]
          dialogClass: 'old-login-dialog-widget'
          title: 'Login'
          width: 400
          open: =>
            @submitAttempted = false
            @$('.old-login-dialog-widget button').each(->
              $(this).attr('tabindex', 1))
            @$('.old-login-dialog-widget span.old-login-failed').text('').hide()
          beforeClose: =>
            @submitAttempted = false
            @cleanUpLoginDialogBox(clearFields: true, removeFocus: true)
          autoOpen: false
        )

      @wrappedDialogBox = @$('.old-login-dialog')

    loginWithEnter: (event) ->
      if event.which is 13
        event.stopPropagation()
        disabled = $("#login" ).button 'option', 'disabled'
        if not disabled
          @$('#login').click()

    open: ->
      @wrappedDialogBox.dialog 'open'

    close: ->
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

      # Remove any validation error icons and explain widgets
      @$('.old-val-err-widget, .old-explanation').remove()

      # Remove any invalid credentials notifications
      @$('.old-login-dialog-widget span.old-login-failed').text('').hide()

      # Restore the default border color of the input fields
      @$('.old-login-dialog-widget input')
        .css('border-color', LoginDialogView.jQueryUIColors.defBo)

    # Let ApplicationSettingsModel handle the authentication attempt
    login: ->

      @submitAttempted = true
      {username, password} = @validate()
      if username and password
        @$('#login').button 'disable'
        Backbone.trigger 'authenticate:login', username, password

    validate: ->

      fields =
        username: @$('#username').val() or false
        password: @$('#password').val() or false
      for name, value of fields
        if value then @$("##{name}-error").hide()
      if @submitAttempted
        for name, value of fields
          if not value then @$("##{name}-error").show().text 'required'
      fields

    logout: ->

      @$('#logout').button 'disable'
      Backbone.trigger 'authenticate:logout'

    openForgotPasswordDialogBox: ->
      console.log 'You want to display the forgot password dialog.'

