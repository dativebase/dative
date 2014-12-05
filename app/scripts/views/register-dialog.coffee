define [
  'backbone'
  './base'
  './../templates/register-dialog'
], (Backbone, BaseView, registerDialogTemplate) ->

  # RegisterDialogView
  # ------------------
  #
  # This is a dialog box for registering an account on a Dative backend server
  # (web service), i.e., FieldDB. For the OLD it should be a message to contact
  # an administrator of an OLD web service, or better a contact form. It is a
  # draggable box created using jQueryUI's # .dialog()

  class RegisterDialogView extends BaseView

    template: registerDialogTemplate

    initialize: ->
      @listenTo Backbone, 'authenticate:fail', @_authenticateFail
      @listenTo Backbone, 'authenticate:end', @_authenticateEnd
      @listenTo Backbone, 'authenticate:success', @_authenticateSuccess
      @listenTo Backbone, 'registerDialog:toggle', @toggle
      @listenTo @model, 'change:loggedIn', @_disableButtons

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
      @$source = @$ '.dative-register-dialog' # outer DIV from template
      @$target = @$ '.dative-register-dialog-target' # outer DIV to which jQueryUI dialog appends
      @_dialogify()
      @_disableButtons()

      # <select name="server" class="server">

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
          @$target.find('button').attr('tabindex', 1).end()
            .find('input').css('border-color',
              RegisterDialogView.jQueryUIColors.defBo)
        open: =>
          @_initializeDialog()
          @_disableButtons()
          @_selectmenuify()
          @_tabindicesNaught()

    _initializeDialog: ->
      @_submitAttempted = false
      @$target.find('.password.passwordConfirm').val('').end()
        .find('span.dative-register-failed').text('').hide()
      @$target.find('.ui-selectmenu-button').focus()

    _disableButtons: ->
      if @model.get 'loggedIn'
        @$target.find('.register').button('disable').end()
          .find('.logout').button('enable').focus().end()
          .find('.forgot-password').button('disable').end()
          .find('.username').attr('disabled', true).end()
          .find('.password').attr('disabled', true)
      else
        @$target.find('.register').button('enable').end()
          .find('.logout').button('disable').end()
          .find('.forgot-password').button('enable').end()
          .find('.username').removeAttr('disabled').end()
          .find('.password').removeAttr('disabled').end()

    _selectmenuify: ->
      @$target.find('select').selectmenu width: 252
      @$target.find('.ui-selectmenu-button').focus()

    # Tabindices=0 and jQueryUI colors
    _tabindicesNaught: ->
      @$('button, select, input, textarea, div.dative-input-display,
        span.ui-selectmenu-button')
        .css("border-color", RegisterDialogView.jQueryUIColors.defBo)
        .attr('tabindex', '0')

    # OLD server responds with validation errors as well as authentication
    # errors. Authentication form should handle as much validation as possible,
    # preventing a request to the server when data are invalid.
    _authenticateFail: (failObject) ->

    _authenticateSuccess: -> @dialogClose()

    _authenticateEnd: -> @_disableButtons()

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

    register: ->
      @_submitAttempted = true
      {server, username, password, passwordConfirm, email} = @validate()
      if server and username and password and passwordConfirm and email
        @$target.find('.register').button 'disable'
        Backbone.trigger 'authenticate:register', username, password

