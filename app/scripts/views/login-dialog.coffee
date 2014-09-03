define [
  'jquery'
  'lodash'
  'backbone'
  './../templates'
  './base'
], ($, _, Backbone, JST, BaseView) ->

  # LoginDialogView
  # ---------------
  #
  # This is a dialog box for authentication, i.e., loggin in, out, and
  # requesting a new password. It is a draggable box created using jQueryUI's
  # .dialog()

  class LoginDialogView extends BaseView

    template: JST['app/scripts/templates/login-dialog.ejs']

    initialize: ->
      @listenTo Backbone, 'authenticate:fail', @authenticateFail
      @listenTo Backbone, 'authenticate:end', @authenticateEnd
      @listenTo Backbone, 'authenticate:success', @authenticateSuccess
      @listenTo Backbone, 'loginDialog:toggle', @toggle
      @listenTo @model, 'change:loggedIn', @disableButtons

    disableButtons: ->
      if @model.get 'loggedIn'
        @$('#login').button 'disable'
        @$('#logout').button('enable').focus()
        @$('#forgot-password').button 'disable'
        @$('.dative-login-dialog-widget .username').attr 'disabled', true
        @$('.dative-login-dialog-widget .password').attr 'disabled', true
      else
        @$('#login').button 'enable'
        @$('#logout').button 'disable'
        @$('#forgot-password').button 'enable'
        @$('.dative-login-dialog-widget .username').removeAttr 'disabled'
        @$('.dative-login-dialog-widget .password').removeAttr 'disabled'
        if @model.get 'username'
          @$('.dative-login-dialog-widget .password').focus()
        else
          @$('.dative-login-dialog-widget .username').focus()
      if @model.get 'username'
        @$('.dative-login-dialog-widget .username').val @model.get 'username'

    # OLD server responds with validation errors as well as authentication
    # errors. Authentication form should handle as much validation as possible,
    # preventing a request to the server when data are invalid.
    authenticateFail: (failObject) ->

    authenticateSuccess: ->
      @close()

    authenticateEnd: ->
      @disableButtons()

    events:
      'click #dative-login-request-button': 'login'
      'keyup .dative-login-dialog-widget .username': 'validate'
      'keydown .dative-login-dialog-widget .username': 'loginWithEnter'
      'keyup .dative-login-dialog-widget .password': 'validate'
      'keydown .dative-login-dialog-widget .password': 'loginWithEnter'

    render: ->
      @$el.append @template(@model.attributes)
      @_dialogify()
      @disableButtons()

    # Transform the login dialog HTML to a jQueryUI dialog box.
    _dialogify: ->

      @$('.dative-login-dialog input').css('border-color',
        LoginDialogView.jQueryUIColors.defBo)
      @$('.dative-login-dialog').dialog(
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
          dialogClass: 'dative-login-dialog-widget'
          title: 'Login'
          width: 400
          open: =>
            @submitAttempted = false
            @$('.dative-login-dialog-widget button').each(->
              $(this).attr('tabindex', 1))
            @$('.dative-login-dialog-widget span.dative-login-failed').text('').hide()
          beforeClose: =>
            @submitAttempted = false
            @cleanUpLoginDialogBox(clearFields: true, removeFocus: true)
          autoOpen: false
        )

      @wrappedDialogBox = @$('.dative-login-dialog')

    loginWithEnter: (event) ->
      if event.which is 13
        event.stopPropagation()
        disabled = $("#login" ).button 'option', 'disabled'
        if not disabled
          @$('#login').click()

    open: ->
      @wrappedDialogBox.dialog 'open'
      @disableButtons()

    close: ->
      @wrappedDialogBox.dialog 'close'

    isOpen: ->
      @wrappedDialogBox.dialog 'isOpen'

    # Clean Up Login Dialog Box -- remove validation error widgets, unbind shortcuts
    cleanUpLoginDialogBox: (options) ->

      options = options or {}

      # Clear the input fields, if requested
      if options.clearFields
        @$('.dative-login-dialog-widget .password').val ''

      # Remove focus, if requested
      #if options.removeFocus
      #@$('.dative-login-dialog-widget input').blur()

      # Remove any validation error icons and explain widgets
      @$('.dative-val-err-widget, .dative-explanation').remove()

      # Remove any invalid credentials notifications
      @$('.dative-login-dialog-widget span.dative-login-failed').text('').hide()

      # Restore the default border color of the input fields
      @$('.dative-login-dialog-widget input')
        .css('border-color', LoginDialogView.jQueryUIColors.defBo)

    # Let ApplicationSettingsModel handle the authentication attempt
    login: ->

      @submitAttempted = true
      {username, password} = @validate()
      if username and password
        @$('#login').button 'disable'
        Backbone.trigger 'authenticate:login', username, password

    # Validate and return field values as object.
    validate: ->

      fields =
        username: @$('.dative-login-dialog-widget .username').val() or false
        password: @$('.dative-login-dialog-widget .password').val() or false
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

    toggle: ->
      if @isOpen() then @close() else @open()

