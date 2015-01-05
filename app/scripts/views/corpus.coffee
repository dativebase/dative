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

  class CorpusView extends BaseView

    tagName: 'div'
    className: ["corpus-widget dative-widget-center ui-widget ui-widget-content",
      "ui-corner-all"].join(' ')

    template: corpusTemplate

    initialize: (options) ->
      @addUserView = new AddUserView()
      @haveFetchedUsers = false
      @applicationSettings = options?.applicationSettings or {}
      @admins = []
      @writers = []
      @readers = []
      @listenToEvents()

    listenToEvents: ->
      @stopListening()
      @undelegateEvents()
      @delegateEvents()
      @listenTo @model, 'fetchStart', @fetchStart
      @listenTo @model, 'fetchUsersStart', @fetchUsersStart
      @listenTo @model, 'fetchUsersEnd', @fetchUsersEnd
      @listenTo @model, 'fetchEnd', @fetchEnd
      @listenTo @addUserView, 'request:addUserToCorpus', @addUserToCorpus

    events:
      'keydown button.toggle-appear': 'toggleAppearKeys'
      'click button.toggle-appear': 'toggle'
      'keydown button.add-user': 'toggleAddUserKeys'
      'click button.add-user': 'toggleAddUser'

    addUserToCorpus: (username, role) ->
      @model.addUserToCorpus username, role

      # 1. POST AUTH_SERVICE/updateroles with JSON:
      # {
      #   authUrl: "https://auth.lingsync.org"
      #   (password: "...")
      #   serverCode: "production"
      #   username: "jrwdunham"
      #   userRoleInfo: {
      #     admin: false
      #     pouchname: "jrwdunham-blackfoot"
      #     reader: true
      #     role: "read_only"
      #     usernameToModify: "jrwdunhamreadonly"
      #     writer: false
      # }
      # Expect: {
      #   corpusadded: true,
      #   info: ["User roles updated successfully for jrwdunhamreadonly"]
      # }
      #
      # 2. POST AUTH_SERVICE/corpusteam with JSON:
      # {
      #   authUrl: "https://auth.lingsync.org"
      #   password: "..."
      #   pouchname: "jrwdunham-blackfoot"
      #   serverCode: "production"
      #   username: "jrwdunham"
      # }
      # Expect: JSON object of users (and roles)
      #
      # 3. GET CORPUS_SERVICE/_users/org.couchdb.user:jrwdunham QUESTION: necessary?
      #
      # Expect: JSON:
      #
      # "{
        # "_id": "org.couchdb.user:jrwdunham",
        # "_rev": "2-dd59dbae9fc8f2c6455c5a98cd288c43",
        # "password_scheme": "pbkdf2",
        # "iterations": 10,
        # "name": "jrwdunham",
        # "roles": [
          # "fielddbuser",
          # "jrwdunham-firstcorpus_admin",
          # "jrwdunham-firstcorpus_commenter",
          # "jrwdunham-firstcorpus_reader",
          # "jrwdunham-firstcorpus_writer",
          # "gina-inuktitut_commenter",
          # "gina-inuktitut_reader",
          # "gina-inuktitut_writer",
          # "lingllama-communitycorpus_commenter",
          # "lingllama-communitycorpus_reader",
          # "lingllama-communitycorpus_writer",
          # "testingharvardimport-firstcorpus_admin",
          # "testingharvardimport-firstcorpus_reader",
          # "testingharvardimport-firstcorpus_writer",
          # "testingharvardimport-hjcopypaste_admin",
          # "testingharvardimport-hjcopypaste_reader",
          # "testingharvardimport-hjcopypaste_writer",
          # "jrwdunham-blackfoot_admin",
          # "jrwdunham-blackfoot_writer",
          # "jrwdunham-blackfoot_reader",
          # "jrwdunham-blackfoot_commenter",
          # "elisekm-eti3_data_tutorial_admin",
          # "elisekm-eti3_data_tutorial_reader",
          # "elisekm-eti3_data_tutorial_writer",
          # "jrwdunham-gitksan_practice_admin",
          # "jrwdunham-gitksan_practice_writer",
          # "jrwdunham-gitksan_practice_reader",
          # "jrwdunham-gitksan_practice_commenter",
          # "jrwdunham-blackfoot_ucalgary_workshop_admin",
          # "jrwdunham-blackfoot_ucalgary_workshop_writer",
          # "jrwdunham-blackfoot_ucalgary_workshop_reader",
          # "jrwdunham-blackfoot_ucalgary_workshop_commenter"
        # ],
        # "previous_rev": "1-38b76b7604734524807868cf18ec5eba",
        # "type": "user",
        # "derived_key": "563df7e28ced77f2a44fe6ff657451bd17205602",
        # "salt": "afff49dddf1a013bcbbaeb009e441657"
      # }"

    removeUserFromCorpus: ->
      # POST AUTH_SERVICE/updateroles with JSON:
      #   authUrl: "https://auth.lingsync.org"
      #   (password: "...")
      #   serverCode: "production"
      #   username: "jrwdunham"
      #   userRoleInfo: {
      #     pouchname: "jrwdunham-blackfoot"
      #     removeUser: true
      #     usernameToModify: "jrwdunhamreadonly"
      #   }
      # }
      #
      # Expect:
      # {
      #   "corpusadded": true,
      #   "info": [
      #   "User roles updated successfully for jrwdunhamreadonly"
      #   ]
      # }

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
        @allUsers = (user.username for user in users.allusers)
        @usersWithoutDuplicates = @getUsersWithoutDuplicates users
        @getUsernames()
        @giveUsernamesToAddUserView()
        @role = @getRole()
        @creator = @getIsCreator()
        @getUserViews()
      @render()
      @open()

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

    getRole: ->
      username = @model.get('applicationSettings').get 'username'
      if username in @adminNames
        'admin'
      else if username in @writerNames
        'writer'
      else
        'reader'

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

    render: ->
      @listenToEvents()
      context = _.extend @model.attributes, isActive: @active()
      @$el.html @template(context)
      @addUserView.setElement @$('div.add-user-widget')
      @addUserView.render().$el.hide()
      @rendered @addUserView
      @guify()
      if @fetching then @spin 'fetching corpus information'
      for roleClass in ['admins', 'writers', 'readers']
        if @[roleClass].length
          container = document.createDocumentFragment()
          for userView in @[roleClass]
            container.appendChild userView.render().el
            @rendered userView
          @$("div.#{roleClass}-widget-body").html container
      @$('.dative-widget-body').first().hide()
      @

    # Add user subviews to the appropriate array of this corpus view.
    getUserViews: ->
      authUrl = @model.get('metadata').authUrl
      pouchname = @model.get('pouchname')
      username = @model.get('applicationSettings').get('username')
      serverCode = @model.get('applicationSettings').get('activeServer')
        .get('serverCode')
      users = @model.get 'users'
      if users and authUrl and username and serverCode and pouchname
        for roleClass in ['admins', 'writers', 'readers']
          for userObject in @usersWithoutDuplicates[roleClass]
            userObject.authUrl = authUrl
            userObject.loggedInUsername = username
            userObject.serverCode = serverCode
            userObject.pouchname = pouchname
            userObject.role = roleClass.substr(0, roleClass.length - 1)
            userModel = new UserModel userObject
            userView = new UserView
              model: userModel
              loggedInUserRole: @role
            @[roleClass].push userView

    # I don't think admins should be redundantly listed as writers and readers.
    getUsersWithoutDuplicates: (users) ->
      adminNames = (user.username for user in users.admins)
      writerNames = (user.username for user in users.writers)
      readerNames = (user.username for user in users.readers)
      usersWithoutDuplicates =
        admins: users.admins
        writers: []
        readers: []
      for writer in users.writers
        if writer.username not in adminNames
          usersWithoutDuplicates.writers.push writer
      for reader in users.readers
        if reader.username not in adminNames and
        reader.username not in writerNames
          usersWithoutDuplicates.readers.push reader
      usersWithoutDuplicates

    toggleAddUserKeys: (event) ->
      if event.which in [13, 32]
        @stopEvent event
        @toggleAddUser event

    toggleAddUser: (event) ->
      @stopEvent event
      contentSuffix = 'form for granting a user access to this corpus'
      if @addUserView.$el.is(':visible')
        @addUserView.$el.slideUp()
        @$('button.add-user').tooltip
          content: "show #{contentSuffix}"
      else
        @open()
        @addUserView.$el.slideDown
          complete: =>
            @addUserView.autoComplete()
        @$('button.add-user').tooltip
          content: "hide #{contentSuffix}"

    toggleAppearKeys: (event) ->
      if event.which in [13, 37, 38, 39, 40] then @stopEvent event
      switch event.which
        when 13 # Enter
          @toggle()
        when 37, 38 # left and up arrows
          @close()
        when 39, 40 # right and down arrows
          @open()

    fetchUsers: ->
      @model.fetchUsers()

    toggle: (event) ->
      if event then @stopEvent event
      $body = @$('.dative-widget-body').first()
      if $body.is ':visible'
        @close()
      else
        @open()

    close: ->
      $body = @$('.dative-widget-body').first()
      if $body.is ':visible'
        @$('button.toggle-appear')
          .button
            icons: {primary: 'ui-icon-triangle-1-e'}
            text: false
          .tooltip content: 'show corpus details'
        $body.slideUp
          complete: =>
            @$('.dative-widget-header').first().addClass 'header-no-body'
            @bodyVisible = false

    open: ->
      if @haveFetchedUsers
        @_open()
      else
        @fetchUsers()

    _open: ->
      $body = @$('.dative-widget-body').first()
      if not $body.is ':visible'
        @$('button.toggle-appear')
          .button
            icons: {primary: 'ui-icon-triangle-1-s'}
            text: false
          .tooltip content: 'hide corpus details'
        @$('.dative-widget-header').first().removeClass 'header-no-body'
        $body.slideDown
          complete: =>
            @bodyVisible = true
            @$('button.toggle-appear').first().focus()

    guify: ->
      @$('button').button().attr('tabindex', 0)

      disabled = true
      if @role is 'admin'
        disabled = false

      @$('button.toggle-appear')
        .button
          icons: {primary: 'ui-icon-triangle-1-e'}
          text: false
        .tooltip()

      @$('button.choose-corpus')
        .button
          icons: {primary: 'ui-icon-star'}
          text: false
        .tooltip()

      @$('button.add-user')
        .button
          icons: {primary: 'ui-icon-person'}
          text: false
          disabled: disabled
        .tooltip()

      if disabled then @$('button.add-user').hide()

      @selectmenuify()
      @tabindicesNaught() # active elements have tabindex=0

    selectmenuify: ->

    # Tabindices=0 and jQueryUI colors
    tabindicesNaught: ->
      @$('select, input')
        .css("border-color", @constructor.jQueryUIColors.defBo)
        .attr('tabindex', 0)

    # Options for spin.js, cf. http://fgnass.github.io/spin.js/
    spinnerOptions:
      lines: 13 # The number of lines to draw
      length: 5 # The length of each line
      width: 2 # The line thickness
      radius: 3 # The radius of the inner circle
      corners: 1 # Corner roundness (0..1)
      rotate: 0 # The rotation offset
      direction: 1 # 1: clockwise -1: counterclockwise
      color: CorpusView.jQueryUIColors.defCo
      speed: 2.2 # Rounds per second
      trail: 60 # Afterglow percentage
      shadow: false # Whether to render a shadow
      hwaccel: false # Whether to use hardware acceleration
      className: 'spinner' # The CSS class to assign to the spinner
      zIndex: 2e9 # The z-index (defaults to 2000000000)
      top: '50%' # Top position relative to parent
      left: '97%' # Left position relative to parent

    spin: (tooltipMessage) ->
      @$('.dative-widget-header').first()
        .spin @spinnerOptions
        .tooltip
          items: 'div'
          content: tooltipMessage
          position:
            my: "left+610 top+8", at: "left top", collision: "flipfit"
        .tooltip 'open'

    stopSpin: ->
      @$('.dative-widget-header').first().spin false

