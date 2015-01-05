define [
  'backbone'
  './base'
  './../templates/add-user'
], (Backbone, BaseView, addUserTemplate) ->

  # Add User View
  # -------------
  #
  # View for adding an existing user to an existing corpus (with a given role).

  class AddUserView extends BaseView

    tagName: 'div'
    className: ['add-user-widget ui-widget ui-widget-content ui-corner-all',
      'dative-widget-center'].join ' '

    initialize: (options) ->
      @submitAttempted = false
      @inputsValid = false
      @allUsers = options?.allUsers or []
      @listenTo Backbone, 'addUserToCorpusEnd', @stopSpin
      @trigger Backbone, 'addUserToCorpusSuccess'

    template: addUserTemplate

    render: ->
      @$el.html @template()
      @guify()
      @

    events:
      'keyup input[name=username]': 'validate'
      'click button.request-add-user': 'requestAddUser'
      # <Enter>-as-submit conflicts with autocomplete <Enter>-as-select
      # 'keydown input[name=username]': 'submitWithEnter'

    requestAddUser: ->
      @submitAttempted = true
      {username, role} = @validate()
      if @inputsValid
        @disableAddUserButton()
        @trigger 'request:addUserToCorpus', username, role

    disableAddUserButton: ->
      @$('input[name=username]').first().focus()
      @$('button.request-add-user').button 'disable'

    enableAddUserButton: ->
      @$('button.request-add-user').button 'enable'

    validate: ->
      username = @$('input[name=username]').val() or false
      role = @$('select[name=role]').val() or false
      if username then @hideErrorMsg()

      errorMsg = null
      if not username
        errorMsg = 'required'
      else if username not in @allUsers
        errorMsg = "There is no such user “#{username}”"
      else if username in @["#{role}Names"]
        errorMsg = "User “#{username}” is already #{@getAn(role)} #{role}"
      else if username is @loggedInUsername
        errorMsg = "You can't demote yourself"

      @inputsValid = if errorMsg then false else true

      if @submitAttempted
        if @inputsValid
          @hideErrorMsg()
          @enableAddUserButton()
        else
          @showErrorMsg errorMsg
          @disableAddUserButton()

      username: username
      role: role

    showErrorMsg: (errorMsg) ->
      @$(".username-error").first().stop().text(errorMsg).fadeIn()

    hideErrorMsg: -> @$(".username-error").first().stop().fadeOut()

    getAn: (input) ->
      if input[0] in ['a', 'e', 'i', 'o', 'u'] then 'an' else 'a'

    submitWithEnter: (event) ->
      if event.which is 13
        @stopEvent event
        event.stopPropagation()
        $addUserButton = @$('button.request-add-user')
        disabled = $addUserButton.button 'option', 'disabled'
        if not disabled then $addUserButton.click()

    autoComplete: ->
      @$('input[name=username]').first()
        .autocomplete source: @allUsers

    guify: ->
      @$('select').selectmenu width: 322
        .next('.ui-selectmenu-button').addClass('role')

      @$('input[name=username]')
        .tooltip
          position:
            my: "right-65 center"
            at: "left center"
            collision: "flipfit"

      @$('.ui-selectmenu-button').filter('.role')
        .tooltip
          items: 'span'
          content: 'which role should the new user have?'
          position:
            my: "right-35 center"
            at: "left center"
            collision: "flipfit"

      @$('button.request-add-user')
        .button()
        .tooltip
          position:
            my: 'left+80 top'
            at: 'left top'
            collision: 'flipfit'

      @$('.dative-add-user-failed').hide()

