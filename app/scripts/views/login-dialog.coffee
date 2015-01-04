define [
  'backbone'
  './base'
  './active-server'
  './../templates/login-dialog'
], (Backbone, BaseView, ActiveServerView, loginDialogTemplate) ->

  # LoginDialogView
  # ---------------
  #
  # This is a dialog box for authentication, i.e., loggin in, out, and
  # requesting a new password. It is a draggable box created using jQueryUI's
  # .dialog()

  class LoginDialogView extends BaseView

    template: loginDialogTemplate

    initialize: ->
      @listenTo Backbone, 'authenticate:fail', @_authenticateFail
      @listenTo Backbone, 'authenticate:end', @_authenticateEnd
      @listenTo Backbone, 'authenticate:success', @_authenticateSuccess
      @listenTo Backbone, 'loginDialog:toggle', @toggle
      @listenTo Backbone, 'logout:success', @logoutSuccess
      @listenTo @model, 'change:loggedIn', @_disableButtons

      @activeServerView = new ActiveServerView
        model: @model
        width: '12.75em'
        label: 'Server *'
        tooltipContent: 'select a server to login to'
        tooltipPosition:
          my: "left+140 top", at: "left top", collision: "flipfit"

    events:
      'keyup .dative-login-dialog-widget .username': 'validate'
      'keydown .dative-login-dialog-widget .username': '_submitWithEnter'
      'keyup .dative-login-dialog-widget .password': 'validate'
      'keydown .dative-login-dialog-widget .password': '_submitWithEnter'

    render: ->
      @$el.append @template()
      @renderActiveServerView()
      @$source = @$ '.dative-login-dialog' # outer DIV from template
      @$target = @$ '.dative-login-dialog-target' # outer DIV to which jQueryUI dialog appends
      @dialogify()
      @tooltipify()
      @_disableButtons()
      @

    renderActiveServerView: ->
      @activeServerView.setElement @$('li.active-server').first()
      @activeServerView.render()
      @rendered @activeServerView

    # Transform the login dialog HTML to a jQueryUI dialog box.
    dialogify: ->
      @$source.find('input').css('border-color',
        LoginDialogView.jQueryUIColors.defBo)
      @$source.dialog
        autoOpen: false
        appendTo: @$target
        buttons: [
            text: 'Register'
            click: => @registerAccount()
            class: 'register'
          # ,
          #   text: 'Forgot password'
          #   click: => @forgotPassword()
          #   class: 'forgot-password'
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
        create: =>
          @$target.find('button, .ui-selectmenu-button').attr('tabindex', 0)
            .end()
            .find('input')
              .css('border-color', LoginDialogView.jQueryUIColors.defBo)
        open: =>
          @_initializeDialog()
          @_disableButtons()

    tooltipify: ->
      @$('button.register')
        .tooltip
          content: 'create a new account'
          items: 'button'
      @$('button.logout')
        .tooltip
          content: 'send a logout request to the server'
          items: 'button'
      @$('button.login')
        .tooltip
          content: 'attempt to login to the server'
          items: 'button'
      @$('input').tooltip
        position:
          my: "left+140 top", at: "left top", collision: "flipfit"

    _initializeDialog: ->
      @_submitAttempted = false
      @$target.find('.password').val('').end()
        .find('span.dative-login-failed').text('').hide()
      @focusAppropriateInput()

    _disableButtons: ->
      if @model.get 'loggedIn'
        @$target.find('.login').button('disable').end()
          .find('.logout').button('enable').focus().end()
          .find('.forgot-password').button('disable').end()
          .find('.username').attr('disabled', true).end()
          .find('.password').attr('disabled', true)
        @activeServerView.disable()
      else
        @$target.find('.login').button('enable').end()
          .find('.logout').button('disable').end()
          .find('.forgot-password').button('enable').end()
          .find('.username').removeAttr('disabled').end()
          .find('.password').removeAttr('disabled').end()
        @activeServerView.enable()

    focusAppropriateInput: ->
      if not @model.get 'loggedIn'
        if @model.get 'username'
          @$target.find('.password').focus()
        else
          @$target.find('.username').focus()
      if @model.get 'username'
        @$target.find('.username').val @model.get('username')

    # OLD server responds with validation errors as well as authentication
    # errors. Authentication form should handle as much validation as possible,
    # preventing a request to the server when data are invalid.
    _authenticateFail: (failObject) ->

    _authenticateSuccess: -> @dialogClose()

    _authenticateEnd: -> @_disableButtons()

    _submitWithEnter: (event) ->
      if event.which is 13
        event.stopPropagation()
        loginButton = @$target.find '.login'
        disabled = loginButton.button 'option', 'disabled'
        if not disabled then loginButton.click()

    dialogOpen: -> @$source.dialog 'open'

    dialogClose: -> @$source.dialog 'close'

    isOpen: -> @$source.dialog 'isOpen'

    toggle: ->
      if @isOpen()
        @dialogClose()
      else
        @dialogOpen()

    dialogOpenWithDefaults: (defaults) ->
      @dialogOpen()
      username = defaults.username or ''
      password = defaults.password or ''
      @$target.find('.username').val username
      @$target.find('.password').val password
      if not @model.get 'loddedIn' then @$target.find('.login').focus()

    # Validate and return field values as object.
    validate: ->
      fields =
        username: @$target.find('.username').val() or false
        password: @$target.find('.password').val() or false
      for name, value of fields
        if value then @$(".#{name}-error").first().hide()
      if @_submitAttempted
        for name, value of fields
          if not value then @$(".#{name}-error").first().show().text 'required'
      fields

    login: ->
      @_submitAttempted = true
      {username, password} = @validate()
      if username and password
        @$target.find('.login').button 'disable'
        Backbone.trigger 'authenticate:login', username, password

    logout: ->
      @$target.find('.logout').button 'disable'
      Backbone.trigger 'authenticate:logout'

    forgotPassword: ->
      Backbone.trigger 'authenticate:forgot-password'

    registerAccount: ->
      @trigger 'request:openRegisterDialogBox'

    logoutSuccess: ->
      @focusAppropriateInput()

