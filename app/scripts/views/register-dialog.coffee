define [
  'backbone'
  './base'
  './active-server'
  './../templates/register-dialog'
], (Backbone, BaseView, ActiveServerView, registerDialogTemplate) ->

  # RegisterDialogView
  # ------------------
  #
  # This is a dialog box for registering an account on a Dative backend server
  # (web service), i.e., FieldDB. For the OLD it should be a message to contact
  # an administrator of an OLD web service or, better yet, a contact form. It
  # is a draggable box created using jQueryUI's `.dialog()`.

  class RegisterDialogView extends BaseView

    template: registerDialogTemplate

    initialize: ->
      @listenTo Backbone, 'registerDialog:toggle', @toggle
      @listenTo @model, 'change:activeServer', @serverDependentRegistration
      @activeServerView = new ActiveServerView
        model: @model, width: 252, label: 'Server *'

    serverDependentRegistration: ->
      serverType = @model.get('activeServer')?.get 'type'
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

    enableRegisterButton: ->
      @$('button.register').button 'enable'

    disableRegisterButton: ->
      @$('button.register').button 'disable'

    events:
      'keyup .dative-register-dialog-widget .username': 'validate'
      'keydown .dative-register-dialog-widget .username': '_submitWithEnter'
      'keyup .dative-register-dialog-widget .password': 'validate'
      'keydown .dative-register-dialog-widget .password': '_submitWithEnter'
      'keyup .dative-register-dialog-widget .passwordConfirm': 'validate'
      'keydown .dative-register-dialog-widget .passwordConfirm': '_submitWithEnter'
      'keyup .dative-register-dialog-widget .email': 'validate'
      'keydown .dative-register-dialog-widget .email': '_submitWithEnter'

    render: ->
      @$el.append @template(@model.attributes)
      @renderActiveServerView()
      @$source = @$ '.dative-register-dialog' # outer DIV from template
      @$target = @$ '.dative-register-dialog-target' # outer DIV to which jQueryUI dialog appends
      @_dialogify()
      @

    renderActiveServerView: ->
      @activeServerView.setElement @$('li.active-server').first()
      @activeServerView.render()
      @rendered @activeServerView

    # Transform the register dialog HTML to a jQueryUI dialog box.
    _dialogify: ->
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
        width: 500
        minWidth: 500
        create: =>
          @$target.find('button').attr('tabindex', 0).end()
            .find('input').css('border-color',
              RegisterDialogView.jQueryUIColors.defBo)
        open: =>
          @_initializeDialog()
          @_selectmenuify()
          @_tabindicesNaught()

    _initializeDialog: ->
      @_submitAttempted = false
      @$target.find('.password.passwordConfirm').val('').end()
        .find('span.dative-register-failed').text('').hide()
      @$target.find('.ui-selectmenu-button').focus()

    _selectmenuify: ->
      @$target.find('select').selectmenu width: 252
      @$target.find('.ui-selectmenu-button').focus()

    # Tabindices=0 and jQueryUI colors
    _tabindicesNaught: ->
      @$('button, select, input, textarea, div.dative-input-display,
        span.ui-selectmenu-button')
        .css("border-color", RegisterDialogView.jQueryUIColors.defBo)
        .attr('tabindex', 0)

    _submitWithEnter: (event) ->
      if event.which is 13
        event.stopPropagation()
        registerButton = @$target.find '.register'
        disabled = registerButton.button 'option', 'disabled'
        if not disabled then registerButton.click()

    dialogOpen: -> @$source.dialog 'open'

    dialogClose: -> @$source.dialog 'close'

    isOpen: -> @$source.dialog 'isOpen'

    toggle: -> if @isOpen() then @dialogClose() else @dialogOpen()

    # Validate and return field values as object.
    # TODO: username and password character restrictions
    # TODO: email validation
    # TODO: password and passwordConfirm must match
    # - required attributes: serverId, username, password, passwordConfirm,
    #   email.
    # - password must equal passwordConfirm
    # TODO @jrwdunham: clean the username with feedback in the register
    # dialog view.
    # TODO @jrwdunham: `appVersionWhenCreated`: Dative current version?
    validate: ->
      fields =
        server: @$target.find('.server').val() or false
        username: @$target.find('.username').val() or false
        password: @$target.find('.password').val() or false
        passwordConfirm: @$target.find('.passwordConfirm').val() or false
        email: @$target.find('.email').val() or false
      for name, value of fields
        if value then @$(".#{name}-error").first().hide()
      if @_submitAttempted
        for name, value of fields
          if not value then @$(".#{name}-error").first().show().text 'required'
      fields

    # notificationMessage = ["We have automatically changed your requested",
    # "username to '#{username}' instead. \n\n(The username you have",
    # "chosen isn't very safe for urls, which means your corpora would be",
    # "potentially inaccessible in old browsers)"].join ' '

    # TODO @jrwdunham: clean the username and notify user of how it will be
    # stored in FieldDB.
    usernameConvertAlert: (username) ->
      convertedUsername = username
        .trim().toLowerCase().replace /[^0-9a-z]/g, ""
      if convertedUsername is not username then convertedUsername


    register: ->
      @_submitAttempted = true
      {server, username, password, passwordConfirm, email} = @validate()
      if server and username and password and passwordConfirm and email
        @$target.find('.register').button 'disable'
        Backbone.trigger 'authenticate:register', username, password

