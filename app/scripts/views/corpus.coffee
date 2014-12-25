define [
  'backbone'
  './base'
  './user'
  './../models/user'
  './../templates/corpus'
], (Backbone, BaseView, UserView, UserModel, corpusTemplate) ->

  # Corpus View
  # ------------
  #

  class CorpusView extends BaseView

    tagName: 'div'
    className: ["corpus-widget dative-widget-center ui-widget ui-widget-content",
      "ui-corner-all"].join(' ')

    template: corpusTemplate

    initialize: ->
      @admins = []
      @writers = []
      @readers = []

    events:
      'keydown button.toggle-appear': 'toggleAppearKeys'
      'click button.toggle-appear': 'toggle'

    listenToEvents: ->
      @listenTo @model, 'usersFetched', @usersFetched
      @delegateEvents()

    usersFetched: ->
      @getUserViews()
      @render()

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
      context = _.extend @model.attributes, isActive: @active()
      @$el.html @template(context)
      @guify()
      for roleClass in ['admins', 'writers', 'readers']
        if @[roleClass].length
          container = document.createDocumentFragment()
          for userView in @[roleClass]
            container.appendChild userView.render().el
            @rendered userView
          @$("div.#{roleClass}-widget-body").html container

      @listenToEvents()
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
      usersWithoutDuplicates = @getUsersWithoutDuplicates users
      if users and authUrl and username and serverCode and pouchname
        for roleClass in ['admins', 'writers', 'readers']
          for userObject in usersWithoutDuplicates[roleClass]
            userObject.authUrl = authUrl
            userObject.loggedInUsername = username
            userObject.serverCode = serverCode
            userObject.pouchname = pouchname
            userObject.role = roleClass.substr(0, roleClass.length - 1)
            userModel = new UserModel userObject
            userView = new UserView model: userModel
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

    toggleAppearKeys: (event) ->
      if event.which in [13, 37, 38, 39, 40] then @stopEvent event
      switch event.which
        when 13 # Enter
          @toggle()
        when 37, 38 # left and up arrows
          @close()
        when 39, 40 # right and down arrows
          @open()

    stopEvent: (event) ->
      event.preventDefault()
      event.stopPropagation()

    toggle: (event) ->
      if event then @stopEvent event

      @$('.toggle-appear .ui-button-icon-primary')
        .toggleClass 'ui-icon-triangle-1-e ui-icon-triangle-1-s'

      @$('.dative-widget-body').first()
        .slideToggle
          complete: =>
            @bodyVisible = @$('.dative-widget-body').is(':visible')

    open: ->
      if not @$('.dative-widget-body').is(':visible')
        @toggle()

    close: ->
      if @$('.dative-widget-body').is(':visible')
        @toggle()

    guify: ->
      @$('button').button().attr('tabindex', 0)
      @$('button.toggle-appear')
        .button
          icons: {primary: 'ui-icon-triangle-1-e'},
          text: false
      @selectmenuify()
      @tabindicesNaught() # active elements have tabindex=0

    selectmenuify: ->
      @$('select').selectmenu width: 320

    # Tabindices=0 and jQueryUI colors
    tabindicesNaught: ->
      @$('select, input')
        .css("border-color", @constructor.jQueryUIColors.defBo)
        .attr('tabindex', 0)

