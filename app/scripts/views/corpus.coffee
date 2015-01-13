define [
  'backbone'
  './base'
  './user'
  './add-user'
  './../models/user'
  './../templates/corpus'
  'jqueryspin'
], (Backbone, BaseView, UserView, AddUserView, UserModel, corpusTemplate) ->

  # Corpus View
  # ------------
  #
  # View for FieldDB corpora.
  #
  # WARNING: this view does not (currently) make use of the write-only role
  # that FieldDB makes available. That is, its logic assumes that a given user
  # can have one and only one role on a given corpus---admin, writer, or
  # reader---and that admins are implicitly also writers and readers and writers
  # are implicitly readers.

  class CorpusView extends BaseView

    tagName: 'div'
    className: ["corpus-widget dative-widget-center ui-widget ui-widget-content",
      "ui-corner-all"].join ' '

    template: corpusTemplate

    initialize: (options) ->
      @addUserView = new AddUserView()
      @haveFetchedUsers = false
      @bodyVisible = false
      @shouldFocusToggleButtonUponOpen = true
      @applicationSettings = options?.applicationSettings or {}
      @admins = []
      @writers = []
      @readers = []
      @listenToEvents()

    listenToEvents: ->
      @stopListening()
      @undelegateEvents()
      @delegateEvents()
      @listenTo @addUserView, 'request:grantRoleToUser', @grantRoleToUser
      @listenToUserViewRevokeAccessRequests()
      @listenTo @model, 'fetchStart', @fetchStart
      @listenTo @model, 'fetchEnd', @fetchEnd
      @listenTo @model, 'fetchUsersStart', @fetchUsersStart
      @listenTo @model, 'fetchUsersEnd', @fetchUsersEnd
      @listenTo @model, 'grantRoleToUserEnd', @stopSpin
      @listenTo @model, 'grantRoleToUserSuccess', @fetchUsersAfterDelay
      @listenTo @model, 'removeUserFromCorpusEnd', @stopSpin
      @listenTo @model, 'removeUserFromCorpusSuccess', @removeUserFromCorpusSuccess

    listenToUserViewRevokeAccessRequests: ->
      for userView in @admins.concat @writers, @readers
        @listenTo userView, 'request:revokeAccess', @removeUserFromCorpusThenFetch

    events:
      'keydown button.toggle-appear': 'toggleAppearKeys'
      'click button.toggle-appear': 'toggle'
      'keydown button.add-user': 'toggleAddUserKeys'
      'click button.add-user': 'toggleAddUser'
      'keydown button.use-corpus': 'useCorpusKeys'
      'click button.use-corpus': 'useCorpus'

    removeUserFromCorpusSuccess: (username) ->
      @removeUserView username
      @removeUserFromRoleNames username
      if @grantRoleToUserRepeat
        args = @grantRoleToUserRepeat
        @grantRoleToUserRepeat = false
        @grantRoleToUser.apply @, args
      if @fetchUsersAfterRemoveUserFromCorpus
        @fetchUsersAfterRemoveUserFromCorpus = false
        @fetchUsersAfterDelay()

    # Remove user(name) from `@adminNames`, `@writerNames` or `@readerNames`
    removeUserFromRoleNames: (username) ->
      oldRole = @getRole username
      @["#{oldRole}Names"] = _.without @["#{oldRole}Names"], username

    removeUserView: (username) ->
      oldRole = @getRole username
      userView = (uv for uv in @["#{oldRole}s"] when uv.model.get('username')\
        is username)[0]
      if userView
        @["#{oldRole}s"] = _.without @["#{oldRole}s"], userView
        userView.$el.fadeOut
          complete: =>
            userView.close()
            @closed userView

    fetchUsersAfterDelay: ->
      # If you don't wait to call /corpusteam, the FieldDB Auth Service won't
      # have the updated info... WARN: I don't like this hack ...
      setTimeout =>
          @fetchUsers()
        ,
          500

    grantRoleToUser: (newRole, username) ->
      # If the user already has a role in this corpus, we have to first make
      # a request to remove the user completely from the corpus and then later
      # make a request to add the new role. For this reason, we must store the
      # new role (and username) in `@grantRoleToUserRepeat`.
      @grantRoleToUserRepeat = false
      currentRole = @getRole username
      if currentRole
        @grantRoleToUserRepeat = [newRole, username]
        @spin "Revoking the #{currentRole} role for user “#{username}”"
        @model.removeUserFromCorpus username
      else
        @spin "Granting the #{newRole} role to user “#{username}”"
        @model.grantRoleToUser newRole, username

    removeUserFromCorpusThenFetch: (username) ->
      @fetchUsersAfterRemoveUserFromCorpus = true
      @removeUserFromCorpus username

    removeUserFromCorpus: (username) ->
      @model.removeUserFromCorpus username

    fetchStart: ->
      @fetching = true

    fetchUsersStart: ->
      @spin 'fetching the users of this corpus'

    fetchEnd: ->
      @fetching = false
      @stopSpin()
      @render()

    fetchUsersEnd: ->
      @haveFetchedUsers = true
      @stopSpin()
      users = @model.get('users')
      if users
        @allUsers = (user.username for user in @getAllUsersArray(users))
        @usersWithoutDuplicates = @getUsersWithoutDuplicates users
        @getUsernames()
        @giveUsernamesToAddUserView()
        @role = @getRole()
        @creator = @getIsCreator()
        @getUserViews()
      @render()
      @fetchThenOpen()

    giveUsernamesToAddUserView: ->
      @addUserView.allUsers = @allUsers
      @addUserView.adminNames = @adminNames
      @addUserView.writerNames = @writerNames
      @addUserView.readerNames = @readerNames
      @addUserView.loggedInUsername =
        @model.get('applicationSettings').get 'username'

    getUsernames: ->
      @adminNames = (user.username for user in @usersWithoutDuplicates.admins)
      @writerNames = (user.username for user in @usersWithoutDuplicates.writers)
      @readerNames = (user.username for user in @usersWithoutDuplicates.readers)

    getIsCreator: ->
      username = @model.get('applicationSettings').get 'username'
      if @utils.startsWith @model.get('pouchname'), username
        true
      else
        false

    getRole: (username) ->
      username = username or @model.get('applicationSettings').get 'username'
      if username in @adminNames
        'admin'
      else if username in @writerNames
        'writer'
      else if username in @readerNames
        'reader'
      else
        null

    activeCorpusChanged: ->
      if @active()
        @$('.dative-widget-body').addClass 'ui-state-highlight'
      else
        @$('.dative-widget-body').removeClass 'ui-state-highlight'

    active: ->
      # TODO @jrwdunham: where is the active corpus info to be stored?
      false

    setModelFromGUI: ->
      @$('input, select').each (index, element) =>
        @model.set $(element).attr('name'), $(element).val()

    renderAddUserView: ->
      @addUserView.setElement @$('div.add-user-widget')
      @addUserView.render()
      @rendered @addUserView

    renderUserViews: ->
      for roleClass in ['admins', 'writers', 'readers']
        if @[roleClass].length
          container = document.createDocumentFragment()
          for userView in @[roleClass]
            container.appendChild userView.render().el
            @rendered userView
          @$("div.#{roleClass}-widget-body").html container

    render: ->
      @listenToEvents()
      @$el.html @template(@getContext())
      @renderAddUserView()
      @guify()
      if @fetching then @spin 'fetching corpus information'
      @renderUserViews()
      if @bodyVisible then @showBody() else @hideBody()
      if @addUserView.visible
        @addUserView.openGUI()
      else
        @addUserView.closeGUI()
      @

    getContext: ->
      context = _.extend @model.attributes, isActive: @active()
      if context.pouchname is 'lingllama-communitycorpus'
        context.title = "LingLlama's Community Corpus"
      # The following works with local FieldDB but not with production, as of Jan 11, 2015
      ###
      [ownerName, corpusName] = context.pouchname.split('-')
      myUsername = @model.get('applicationSettings').get 'username'
      if corpusName is 'firstcorpus'
        if myUsername is ownerName
          context.modifiedTitle = "my #{context.title}"
        else
          context.modifiedTitle = "#{ownerName}'s #{context.title}"
      else
        context.modifiedTitle = context.title
      ###
      context

    # Add user subviews to the appropriate array of this corpus view.
    getUserViews: ->
      authUrl = @model.get('applicationSettings').get('activeServer').get('url')
      pouchname = @model.get('pouchname')
      username = @model.get('applicationSettings').get('username')
      serverCode = @model.get('applicationSettings').get('activeServer')
        .get('serverCode')
      users = @model.get 'users'
      if users and authUrl and username and serverCode and pouchname
        for roleClass in ['admins', 'writers', 'readers']
          for userObject in @usersWithoutDuplicates[roleClass]
            if userObject.username not in (uv.model.get('username') for uv in @[roleClass])
              userObject.authUrl = authUrl
              userObject.loggedInUsername = username
              userObject.serverCode = serverCode
              userObject.pouchname = pouchname
              userObject.role = roleClass[0..-2]
              userModel = new UserModel userObject
              userView = new UserView
                model: userModel
                loggedInUserRole: @role
              @[roleClass].push userView

    # I don't think admins should be redundantly listed as writers and readers.
    getUsersWithoutDuplicates: (users) ->
      adminNames = (user.username for user in @getAdminsArray(users))
      writerNames = (user.username for user in @getWritersArray(users))
      readerNames = (user.username for user in @getReadersArray(users))
      usersWithoutDuplicates =
        admins: users.admins or []
        writers: []
        readers: []
      for writer in @getWritersArray(users)
        if writer.username not in adminNames
          usersWithoutDuplicates.writers.push writer
      for reader in @getReadersArray(users)
        if reader.username not in adminNames and
        reader.username not in writerNames
          usersWithoutDuplicates.readers.push reader
      usersWithoutDuplicates

    getAllUsersArray: (users) -> if users.allusers? then users.allusers else []
    getAdminsArray: (users) -> if users.admins? then users.admins else []
    getWritersArray: (users) -> if users.writers? then users.writers else []
    getReadersArray: (users) -> if users.readers? then users.readers else []

    useCorpusKeys: (event) ->
      if event.which in [13, 32]
        @stopEvent event
        @useCorpus event

    useCorpus: (event) ->
      if event then @stopEvent event
      Backbone.trigger 'request:browseFieldDBCorpus', @model.get('pouchname')

    toggleAddUserKeys: (event) ->
      if event.which in [13, 32]
        @stopEvent event
        @toggleAddUser event

    setAddUserButtonState: ->
      contentSuffix = 'interface for managing corpus users'
      if @addUserView.visible
        @$('button.add-user').tooltip
          content: "show #{contentSuffix}"
      else
        @$('button.add-user').tooltip
          content: "hide #{contentSuffix}"

    toggleAddUser: (event) ->
      @stopEvent event
      @setAddUserButtonState()
      if @addUserView.visible
        @addUserView.closeGUI()
      else
        @fetchThenOpen()
        @addUserView.openGUI()

    toggleAppearKeys: (event) ->
      if event.which in [13, 37, 38, 39, 40] then @stopEvent event
      switch event.which
        when 13 # Enter
          @toggle()
        when 37, 38 # left and up arrows
          @closeBody()
        when 39, 40 # right and down arrows
          @fetchThenOpen()

    fetchUsers: ->
      @model.fetchUsers()

    toggle: (event) ->
      if event then @stopEvent event
      $body = @$('.dative-widget-body').first()
      if $body.is ':visible'
        @closeBody()
      else
        @fetchThenOpen()

    closeBody: ->
      @setBodyStateClosed()
      $body = @$('.dative-widget-body').first()
      if $body.is ':visible' then $body.slideUp()

    hideBody: ->
      @setBodyStateClosed()
      @$('.dative-widget-body').first().hide()

    setBodyStateClosed: ->
      @bodyVisible = false
      @setHeaderStateClosed()
      @setToggleButtonStateClosed()

    setHeaderStateClosed: ->
      @$('.dative-widget-header').first().addClass 'header-no-body'

    setToggleButtonStateClosed: ->
      @$('button.toggle-appear')
        .find('i').removeClass('fa-caret-down').addClass('fa-caret-right').end()
        .button()
        .tooltip
          content: 'show corpus details'

    fetchThenOpen: ->
      if @haveFetchedUsers
        @openBody()
      else
        @fetchUsers()

    openBody: ->
      @setBodyStateOpen()
      $body = @$('.dative-widget-body').first()
      if not $body.is ':visible'
        $body.slideDown
          complete: =>
            if @shouldFocusToggleButtonUponOpen
              @focusToggleButton()
            else
              @shouldFocusToggleButtonUponOpen = true

    showBody: ->
      @setBodyStateOpen()
      @$('.dative-widget-body').first().show()

    focusToggleButton: ->
      @$('button.toggle-appear').first().focus()

    setBodyStateOpen: ->
      @bodyVisible = true
      @setHeaderStateOpen()
      @setToggleButtonStateOpen()

    setHeaderStateOpen: ->
      @$('.dative-widget-header').first().removeClass 'header-no-body'

    setToggleButtonStateOpen: ->
      @$('button.toggle-appear')
        .find('i').addClass('fa-caret-down').removeClass('fa-caret-right').end()
        .button()
        .tooltip content: 'hide corpus details'

    guify: ->
      @$('button').button().attr('tabindex', 0)

      disabled = true
      if @role is 'admin'
        disabled = false

      @$('button.toggle-appear')
        .button()
        .tooltip
          position:
            my: "right-10 center"
            at: "left center"
            collision: "flipfit"

      @$('button.use-corpus')
        .button()
        .tooltip
          position:
            my: "right-45 center"
            at: "left center"
            collision: "flipfit"

      @$('button.add-user')
        .button
          disabled: disabled
        .tooltip
          position:
            my: "right-80 center"
            at: "left center"
            collision: "flipfit"

      if disabled then @$('button.add-user').hide()

      @selectmenuify()
      @tabindicesNaught() # active elements have tabindex=0

    selectmenuify: ->

    # Tabindices=0 and jQueryUI colors
    tabindicesNaught: ->
      @$('select, input')
        .css("border-color", @constructor.jQueryUIColors.defBo)
        .attr('tabindex', 0)

    spinnerOptions: ->
      _.extend BaseView::spinnerOptions, {top: '50%', left: '97%'}

    spin: (tooltipMessage) ->
      @$('.dative-widget-header').first()
        .spin @spinnerOptions()
        .tooltip
          items: 'div'
          content: tooltipMessage
          position:
            my: "left+610 top+8", at: "left top", collision: "flipfit"
        .tooltip 'open'

    stopSpin: ->
      @$('.dative-widget-header').first().spin false

