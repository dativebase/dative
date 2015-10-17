define [
  'backbone'
  './base'
  './user'
  './edit-corpus'
  './add-user'
  './../models/user'
  './../utils/globals'
  './../templates/corpus'
  'jqueryspin'
], (Backbone, BaseView, UserView, EditCorpusView, AddUserView, UserModel,
  globals, corpusTemplate) ->

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
      @editCorpusView = new EditCorpusView model: @model
      @haveFetchedUsers = false
      @bodyVisible = false
      @shouldFocusToggleButtonUponOpen = true
      @applicationSettings = options?.applicationSettings or {}
      @activeFieldDBCorpus = options?.activeFieldDBCorpus
      @admins = []
      @writers = []
      @readers = []
      @listenToEvents()

    listenToEvents: ->
      @stopListening()
      @undelegateEvents()
      @delegateEvents()
      @listenTo @addUserView, 'request:grantRoleToUser', @grantRoleToUser
      @listenTo @editCorpusView, 'request:editCorpus', @editCorpus
      @listenToUserViewRevokeAccessRequests()
      @listenTo @model, 'fetchStart', @fetchStart
      @listenTo @model, 'fetchEnd', @fetchEnd
      @listenTo @model, 'fetchUsersStart', @fetchUsersStart
      @listenTo @model, 'fetchUsersEnd', @fetchUsersEnd
      @listenTo @model, 'grantRoleToUserEnd', @stopSpin
      @listenTo @model, 'grantRoleToUserSuccess', @fetchUsersAfterDelay
      @listenTo @model, 'removeUserFromCorpusEnd', @stopSpin
      @listenTo @model, 'removeUserFromCorpusSuccess', @removeUserFromCorpusSuccess
      @listenTo @model, 'updateCorpusSuccess', @updateCorpusSuccess
      @listenTo @model, 'updateCorpusEnd', @stopSpin

    listenToUserViewRevokeAccessRequests: ->
      for userView in @admins.concat @writers, @readers
        @listenTo userView, 'request:revokeAccess', @removeUserFromCorpusThenFetch

    events:
      'keydown button.toggle-appear': 'toggleAppearKeys'
      'click button.toggle-appear': 'toggle'
      'keydown button.add-user': 'toggleAddUserKeys'
      'click button.add-user': 'toggleAddUser'
      'keydown button.edit-corpus': 'toggleEditCorpusKeys'
      'click button.edit-corpus': 'toggleEditCorpus'
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

    updateCorpusSuccess: (username) ->
      console.log 'we successfully updated the title and description of this corpus'

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

    # Tell the model to edit the corpus details on the server.
    editCorpus: (newTitle, newDescription) ->
      @spin "Updating the title and description of this corpus"
      @model.updateCorpus newTitle, newDescription

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
      if @model.get('team').username == username
        true # TODO GC: why does the creator matter? The corpus has a 'team' which says who it belongs to, and this could change over time so dont look in the dbname for this
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
      if @isActive()
        @$('.dative-widget-body').addClass 'ui-state-highlight ui-corner-bottom'
      else
        @$('.dative-widget-body').removeClass 'ui-state-highlight ui-corner-bottom'

    isActive: ->
      activeFieldDBCorpusPouchname = globals.applicationSettings.get 'activeFieldDBCorpus'
      dbname = @model.get 'dbname'
      if activeFieldDBCorpusPouchname is dbname then true else false

    setModelFromGUI: ->
      @$('input, select').each (index, element) =>
        @model.set $(element).attr('name'), $(element).val()

    renderAddUserView: ->
      @addUserView.setElement @$('div.add-user-widget')
      @addUserView.render()
      @rendered @addUserView

    renderEditCorpusView: ->
      @editCorpusView.setElement @$('div.edit-corpus-widget')
      @editCorpusView.render()
      @rendered @editCorpusView

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
      @renderEditCorpusView()
      @renderAddUserView()
      @guify()
      if @fetching then @spin 'fetching corpus information'
      @renderUserViews()
      if @bodyVisible then @showBody() else @hideBody()
      @openAddUserView()
      @openEditCorpusView()
      @

    openAddUserView: ->
      @setAddUserButtonState()
      if @addUserView.visible
        @addUserView.openGUI()
      else
        @addUserView.closeGUI()

    openEditCorpusView: ->
      @setEditCorpusButtonState()
      if @editCorpusView.visible
        @editCorpusView.openGUI()
      else
        @editCorpusView.closeGUI()

    getContext: ->
      context = @model.corpus.toJSON()
      if context.dbname is 'lingllama-communitycorpus'
        context.title = "LingLlama's Community Corpus"
      # The following works with local FieldDB but not with production, as of Jan 11, 2015
      ###
      [ownerName, corpusName] = context.dbname.split('-')
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
      dbname = @model.get('dbname')
      username = @model.get('applicationSettings').get('username')
      serverCode = @model.get('applicationSettings').get('activeServer')
        .get('serverCode')
      users = @model.get 'users'
      if users and authUrl and username and serverCode and dbname
        for roleClass in ['admins', 'writers', 'readers']
          for userObject in @usersWithoutDuplicates[roleClass]
            if userObject.username not in (uv.model.get('username') for uv in @[roleClass])
              userObject.authUrl = authUrl
              userObject.loggedInUsername = username
              userObject.serverCode = serverCode
              userObject.dbname = dbname
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
      @setUseCorpusButtonStateActive()
      Backbone.trigger 'useFieldDBCorpus', @model.get('dbname')

    toggleAddUserKeys: (event) ->
      if event.which in [13, 32]
        @stopEvent event
        @toggleAddUser event

    toggleEditCorpusKeys: (event) ->
      if event.which in [13, 32]
        @stopEvent event
        @toggleEditCorpus event

    setAddUserButtonState: ->
      contentSuffix = 'interface for managing the users of this corpus'
      if @addUserView.visible
        @$('button.add-user').tooltip
          content: "hide #{contentSuffix}"
      else
        @$('button.add-user').tooltip
          content: "show #{contentSuffix}"

    setEditCorpusButtonState: ->
      contentSuffix = 'interface for editing the details of this corpus'
      if @editCorpusView.visible
        @$('button.edit-corpus').tooltip
          content: "hide #{contentSuffix}"
      else
        @$('button.edit-corpus').tooltip
          content: "show #{contentSuffix}"

    toggleAddUser: (event) ->
      @stopEvent event
      if @addUserView.visible
        @addUserView.closeGUI()
      else
        @fetchThenOpen()
        @addUserView.openGUI()
      @setAddUserButtonState()

    toggleEditCorpus: (event) ->
      @stopEvent event
      if @editCorpusView.visible
        @editCorpusView.closeGUI()
      else
        @fetchThenOpen()
        @editCorpusView.openGUI()
      @setEditCorpusButtonState()

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

    setToggleButtonStateClosed: ->
      @$('button.toggle-appear')
        .find('i').removeClass('fa-caret-down').addClass('fa-caret-right').end()
        .button()
        .tooltip
          content: 'show corpus details'

    setUseCorpusButtonStateInactive: ->
      @$('button.use-corpus')
        .find('i').addClass('fa-toggle-off').removeClass('fa-toggle-on').end()
        .button()
        .tooltip content: 'activate this corpus and view its data'

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

    setToggleButtonStateOpen: ->
      @$('button.toggle-appear')
        .find('i').addClass('fa-caret-down').removeClass('fa-caret-right').end()
        .button()
        .tooltip content: 'hide corpus details'

    setUseCorpusButtonStateActive: ->
      @$('button.use-corpus')
        .find('i').addClass('fa-toggle-on').removeClass('fa-toggle-off').end()
        .button()
        .tooltip content: 'this is the active corpus; click here to browse its data'

    guify: ->
      @$('button').button().attr('tabindex', 0)

      disabled = if @role is 'admin' then false else true

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

      @$('button.edit-corpus')
        .button()
        .tooltip
          position:
            my: "right-80 center"
            at: "left center"
            collision: "flipfit"

      @$('button.add-user')
        .button
          disabled: disabled
        .tooltip
          position:
            my: "right-115 center"
            at: "left center"
            collision: "flipfit"

      if disabled then @$('button.add-user').hide()

      @tabindicesNaught() # active elements have tabindex=0

      if @isActive()
        @setUseCorpusButtonStateActive()
      else
        @setUseCorpusButtonStateInactive()

      @$('.active-indicator').css "color", @constructor.jQueryUIColors().defCo

    # Tabindices=0 and jQueryUI colors
    tabindicesNaught: ->
      @$('select, input, textarea')
        .css("border-color", @constructor.jQueryUIColors().defBo)
        .attr('tabindex', 0)

    spinnerOptions: ->
      _.extend BaseView::spinnerOptions(), {top: '50%', left: '97%'}

    spin: (tooltipMessage) ->
      @$('.dative-widget-header').first()
        .spin @spinnerOptions()
        .tooltip
          content: tooltipMessage
          position:
            my: "left+1110 top+8", at: "left top", collision: "flipfit"
        .tooltip 'open'

    stopSpin: ->
      @$('.dative-widget-header').first().spin false

