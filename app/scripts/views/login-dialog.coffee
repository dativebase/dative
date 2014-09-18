define [
  'backbone'
  './../templates'
  './base'
], (Backbone, JST, BaseView) ->

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

    events:
      'keyup .dative-login-dialog-widget .username': 'validate'
      'keydown .dative-login-dialog-widget .username': 'submitWithEnter'
      'keyup .dative-login-dialog-widget .password': 'validate'
      'keydown .dative-login-dialog-widget .password': 'submitWithEnter'

    render: ->
      @$el.append @template(@model.attributes)
      @$source = @$ '.dative-login-dialog' # outer DIV from template
      @$target = @$ '.dative-login-dialog-target' # outer DIV to which jQueryUI dialog appends
      @_dialogify()
      @disableButtons()

    disableButtons: ->
      if @model.get 'loggedIn'
        @$target.find('.login').button('disable').end()
          .find('.logout').button('enable').focus().end()
          .find('.forgot-password').button('disable').end()
          .find('.username').attr('disabled', true).end()
          .find('.password').attr('disabled', true)
      else
        @$target.find('.login').button('enable').end()
          .find('.logout').button('disable').end()
          .find('.forgot-password').button('enable').end()
          .find('.username').removeAttr('disabled').end()
          .find('.password').removeAttr('disabled').end()
        if @model.get 'username'
          @$target.find('.password').focus()
        else
          @$target.find('.username').focus()
      if @model.get 'username'
        @$target.find('.username').val @model.get('username')

    # OLD server responds with validation errors as well as authentication
    # errors. Authentication form should handle as much validation as possible,
    # preventing a request to the server when data are invalid.
    authenticateFail: (failObject) ->

    authenticateSuccess: ->
      @dialogClose()

    authenticateEnd: ->
      @disableButtons()

    # Transform the login dialog HTML to a jQueryUI dialog box.
    _dialogify: ->
      @$source.find('input').css('border-color',
        LoginDialogView.jQueryUIColors.defBo)
      @$source.dialog
        buttons: [
            text: 'Forgot password'
            click: => @openForgotPasswordDialogBox
            class: 'forgot-password'
          ,
            text: 'Logout'
            click: => @logout()
            class: 'logout'
          ,
            text: 'Login'
            click: => @login()
            class: 'login'
        ]
        dialogClass: 'dative-login-dialog-widget'
        title: 'Login'
        width: 400
        open: =>
          self = this
          @submitAttempted = false
          @$target.find('button').each(->
            self.$(this).attr('tabindex', 1))
          @$target.find('span.dative-login-failed').text('').hide()
        beforeClose: =>
          @submitAttempted = false
          @_clean()
        autoOpen: false
        appendTo: @$target

    submitWithEnter: (event) ->
      if event.which is 13
        event.stopPropagation()
        disabled = @$target.find('.login' ).button 'option', 'disabled'
        if not disabled
          @$target.find('.login').click()

    dialogOpen: ->
      @$source.dialog 'open'
      @disableButtons()

    dialogClose: ->
      @$source.dialog 'close'

    isOpen: ->
      @$source.dialog 'isOpen'

    # Clean Up Login Dialog Box -- remove validation error widgets, unbind shortcuts
    _clean: ->
      @$target.find('.password').val('').end()
        .find('.dative-val-err-widget, .dative-explanation').remove().end()
        .find('span.dative-login-failed').text('').hide().end()
        .find('input').css('border-color', LoginDialogView.jQueryUIColors.defBo)

    # Let ApplicationSettingsModel handle the authentication attempt
    login: ->

      @submitAttempted = true
      {username, password} = @validate()
      if username and password
        @$target.find('.login').button 'disable'
        Backbone.trigger 'authenticate:login', username, password

    # Validate and return field values as object.
    validate: ->

      fields =
        username: @$target.find('.username').val() or false
        password: @$target.find('.password').val() or false
      for name, value of fields
        if value then @$(".#{name}-error").first().hide()
      if @submitAttempted
        for name, value of fields
          if not value then @$(".#{name}-error").first().show().text 'required'
      fields

    logout: ->

      @$target.find('.logout').button 'disable'
      Backbone.trigger 'authenticate:logout'

    openForgotPasswordDialogBox: ->
      console.log 'You want to display the forgot password dialog.'

    toggle: ->
      if @isOpen() then @dialogClose() else @dialogOpen()

