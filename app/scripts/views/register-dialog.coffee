define [
  'backbone'
  './base'
  './active-server'
  './../templates/register-dialog'
  './../utils/utils'
], (Backbone, BaseView, ActiveServerView, registerDialogTemplate, utils) ->

  # RegisterDialogView
  # ------------------
  #
  # This is a dialog box for registering an account on a Dative server, i.e.,
  # a FieldDB web service. When the selected server is an OLD web service, a
  # message is displayed which instructs the user to contact the administrator
  # of a particular OLD web service or to install/setup an OLD of their own.

  class RegisterDialogView extends BaseView

    template: registerDialogTemplate

    initialize: ->
      @listenTo Backbone, 'registerDialog:toggle', @toggle
      @listenTo @model, 'change:activeServer', @serverDependentRegistration
      @listenTo Backbone, 'authenticate:end', @registerEnd
      @listenTo Backbone, 'register:fail', @registerFail
      @listenTo Backbone, 'register:success', @registerSuccess

      @activeServerView = new ActiveServerView
        model: @model, width: 252, label: 'Server *'


    registerFail: (reason) ->
      console.log "The register attempt failed. Reason #{reason}"

    registerEnd: ->
      @enableRegisterButton()

    registerSuccess: (responseJSON) ->
      console.log 'The register attempt succeeded.'
      console.log JSON.stringify(responseJSON, undefined, 2)

    # WARN: `input` event requires a modern browser; `keyup` is almost as good.
    events:
      'input .dative-register-dialog-widget .username': 'validate'
      'keydown .dative-register-dialog-widget .username': 'submitWithEnter'
      'input .dative-register-dialog-widget .password': 'validate'
      'keydown .dative-register-dialog-widget .password': 'submitWithEnter'
      'input .dative-register-dialog-widget .passwordConfirm': 'validate'
      'keydown .dative-register-dialog-widget .passwordConfirm': 'submitWithEnter'
      'input .dative-register-dialog-widget .email': 'validate'
      'keydown .dative-register-dialog-widget .email': 'submitWithEnter'

    render: ->
      @$el.append @template(@model.attributes)
      @renderActiveServerView()
      @serverDependentRegistration()
      @$source = @$ '.dative-register-dialog' # outer DIV from template
      @$target = @$ '.dative-register-dialog-target' # outer DIV to which jQueryUI dialog appends
      @dialogify()
      @

    renderActiveServerView: ->
      @activeServerView.setElement @$('li.active-server').first()
      @activeServerView.render()
      @rendered @activeServerView

    getActiveServerType: ->
      @model.get('activeServer')?.get 'type'

    submitWithEnter: (event) ->
      if event.which is 13
        event.preventDefault()
        event.stopPropagation()
        registerButton = @$target.find '.register'
        disabled = registerButton.button 'option', 'disabled'
        if not disabled then registerButton.click() # calls `@register()`

    # Triggers Backbone-wide event for model to make register request.
    # Backbone.trigger 'longTask:deregister', taskId
    # Backbone.trigger 'authenticate:end'
    register: ->
      console.log '\nWe tried to register'
      @_submitAttempted = true
      params = @validate()
      {serverCode, username, password, email} = params
      if serverCode and username and password and email
        console.log 'registration about to commence\n'
        @$target.find('.register').button 'disable'
        Backbone.trigger 'authenticate:register', params

    registerRequestComplete: ->
      # re-enable the register button, IF validation passes...
      return


    # Modal dialog-specific stuff (jQueryUI)
    # ==========================================================================

    # Transform the register dialog HTML to a jQueryUI dialog box.
    dialogify: ->
      @$source.find('input').css('border-color',
        RegisterDialogView.jQueryUIColors.defBo)
      @$source.dialog
        position: my: "center+30", at: "center+30", of: window
        autoOpen: false
        appendTo: @$target
        buttons: [
            text: 'Register'
            click: => @register()
            class: 'register'
        ]
        dialogClass: 'dative-register-dialog-widget'
        title: 'Register'
        width: 'auto'
        create: =>
          @$target.find('button').attr('tabindex', 0).end()
            .find('input').css('border-color',
              RegisterDialogView.jQueryUIColors.defBo)
        open: =>
          @initializeDialog()
          @selectmenuify()
          @tabindicesNaught()
          @disableRegisterButton()

    initializeDialog: ->
      @_submitAttempted = false
      @$target.find('.password.passwordConfirm').val('').end()
        .find('span.dative-register-validation').text('').hide()
      @$target.find('.ui-selectmenu-button').focus()

    dialogOpen: -> @$source.dialog 'open'

    dialogClose: -> @$source.dialog 'close'

    isOpen: -> @$source.dialog 'isOpen'

    toggle: -> if @isOpen() then @dialogClose() else @dialogOpen()


    # Show registration fields only for FieldDB servers
    # ==========================================================================

    serverDependentRegistration: ->
      serverType = @getActiveServerType()
      switch serverType
        when 'OLD' then @oldHelp()
        when 'FieldDB' then @registrationActive()
        else @registrationInactive()

    registrationActive: ->
      @showInputs()
      @hideOLDHelpText()
      @hideGeneralHelpText()
      @enableRegisterButton()

    oldHelp: ->
      @hideInputs()
      @showOLDHelpText()
      @hideGeneralHelpText()
      @disableRegisterButton()

    registrationInactive: ->
      @hideInputs()
      @hideOLDHelpText()
      @showGeneralHelpText()
      @disableRegisterButton()

    showInputs: ->
      @$('.fielddb').stop().slideDown duration: 'medium', queue: false

    hideInputs: ->
      @$('.fielddb').stop().slideUp()

    showOLDHelpText: ->
      @$('.old').stop().slideDown duration: 'medium', queue: false

    hideOLDHelpText: ->
      @$('.old').stop().slideUp duration: 'medium', queue: false

    showGeneralHelpText: ->
      @$('.none').stop().slideDown duration: 'medium', queue: false

    hideGeneralHelpText: ->
      @$('.none').stop().slideUp duration: 'medium', queue: false


    # General GUI manipulation
    # ==========================================================================

    enableRegisterButton: ->
      @$('button.register').button 'enable'

    disableRegisterButton: ->
      @$('button.register').button 'disable'

    selectmenuify: ->
      @$target.find('select').selectmenu width: 252
      @$target.find('.ui-selectmenu-button').focus()

    # Tabindices=0 and jQueryUI colors
    tabindicesNaught: ->
      @$('button, select, input, textarea, div.dative-input-display,
        span.ui-selectmenu-button')
        .css("border-color", RegisterDialogView.jQueryUIColors.defBo)
        .attr('tabindex', 0)


    # Validation logic
    # ==========================================================================

    # Validate register form input and return field values as object.
    # Side-effects are button dis/en-abling and message popups.
    validate: ->
      inputs =
        serverCode: @validateServerCode()
        username: @validateUsername()
        password: @validatePassword()
        email: @validateEmail()
      if @inputsAreValid inputs
        @enableRegisterButton()
      else
        @disableRegisterButton()
      inputs

    # Inputs are valid if they don't contain falsey values.
    inputsAreValid: (inputs) ->
      if _.filter(_.values(inputs), (x) -> not x).length then false else true

    validateServerCode: ->
      serverType = @getActiveServerType()
      if serverType is 'FieldDB'
        @$target.find('.activeServer').val()
      else
        null

    # TODO @jrwdunham: clean the username in situ
    validateUsername: ->
      username = @$target.find('.username').val().trim()
      username = @required 'username', username
      if username
        convertedUsername = @convertUsername username
        if convertedUsername is username
          @$(".username-validation").first().hide()
        else
          @showInfo 'username', 'lowercase letters and numbers only'
          @replaceUsernameInField convertedUsername
        convertedUsername
      else
        null

    # TODO @jrwdunham: convert username in the input, with notification.
    convertUsername: (username) ->
      username.toLowerCase().replace /[^0-9a-z]/g, ""

    replaceUsernameInField: (convertedUsername) ->
      @$('input.username').first().val convertedUsername

    validatePassword: ->
      password = @$target.find('.password').val().trim()
      passwordConfirm = @$target.find('.passwordConfirm').val().trim()
      password = @required 'password', password
      passwordConfirm = @required 'passwordConfirm', passwordConfirm
      if password and passwordConfirm
        if password is passwordConfirm
          @$(".password-validation").first().hide()
          @$(".passwordConfirm-validation").first().hide()
          password
        else
          @showError 'password', "passwords don't match"
          @showError 'passwordConfirm', "passwords don't match"
          null
      else
        null

    # NOTE: we are not REQUIRING a valid email, just warning about probably
    # malformed ones. This is because there are probably *some* valid emails
    # that will fail this validation ...
    # NOTE also: FieldDB does server-side email validation by attempting to
    # send a registration confirmation email. I think the result of this attempt
    # is indicated in the returned JSON.
    validateEmail: ->
      email = @$target.find('.email').val().trim()
      email = @required 'email', email
      if email and not utils.emailIsValid email
        @showInfo 'email', "warning: this doesn't look like a valid email"
      email

    # `attr` must have a value; indicate that and return `null` if no `val`.
    required: (attr, val) ->
      if val
        @$(".#{attr}-validation").first().hide()
        val
      else
        if @_submitAttempted then @showError attr, 'required'
        null

    # Show INFO message for the `attr`ibute, e.g., email, username
    showInfo: (attr, msg) ->
      @$(".#{attr}-validation").first()
        .removeClass('ui-state-error')
        .addClass('ui-state-highlight')
        .text(msg)
        .show()

    # Show ERROR message for the `attr`ibute, e.g., email, username
    showError: (attr, msg) ->
      @$(".#{attr}-validation").first()
        .addClass('ui-state-error')
        .removeClass('ui-state-highlight')
        .text(msg)
        .show()

    # TODO @jrwdunham: put this in the (to-be-created) Help JSON object
    # notificationMessage = ["We have automatically changed your requested",
    # "username to '#{username}' instead. \n\n(The username you have",
    # "chosen isn't very safe for urls, which means your corpora would be",
    # "potentially inaccessible in old browsers)"].join ' '
