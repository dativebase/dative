define [
  'backbone'
  './base'
  './servers'
  './active-server'
  './old-application-settings-resource'
  './../models/old-application-settings'
  './../collections/old-application-settings'
  './../utils/globals'
  './../templates/application-settings'
], (Backbone, BaseView, ServersView, ActiveServerView,
  OLDApplicationSettingsResourceView, OLDApplicationSettingsModel,
  OLDApplicationSettingsCollection, globals, applicationSettingsTemplate) ->

  # Application Settings View
  # -------------------------
  #
  # View for viewing and modifying the settings of this Dative application.
  # These settings are currently divided into 3 sections/parts:
  #
  # 1. Servers: the servers that we expect to be connecting to via this Dative
  #    application. Currently, these are only persisted locally (LocalStorage).
  #
  # 2. Appearance: choose the jQueryUI theme that you want. Choice is persisted
  #    in the app-wide `ApplicationSettingsModel` instance in LocalStorage
  #    (same one that is used to persist the server settings in (1)).
  #
  # 3. Server Settings: currently this is not yet implemented. When logged in
  #    to an OLD web service, this should display the most recent OLD
  #    application settings resource.

  class ApplicationSettingsView extends BaseView

    tagName: 'div'
    template: applicationSettingsTemplate

    events:
      'click button.all-settings': 'showOnlySettingsList'
      'click .big-button.servers': 'showServersInterface'
      'click .big-button.appearance': 'showAppearanceInterface'
      'click .big-button.server-settings': 'showServerSettingsInterface'
      'click .jquery-theme-image-container': 'changeJQueryUITheme'
      'click .application-settings-help': 'applicationSettingsHelp'
      'keydown .big-button': 'keydownBigButton'
      'keydown .jquery-theme-image-container': 'keydownJQueryThemeImageContainer'
      'selectmenuchange select[name=activeServer]': 'setModelFromGUI'

    # Tell the Help dialog to open itself and search for "application settings"
    # and scroll to the Xth match. WARN: this is brittle because if the help
    # HTML changes, then the Xth match may not be what we want....
    applicationSettingsHelp: ->
      Backbone.trigger(
        'helpDialog:openTo',
        searchTerm: "application settings"
        scrollToIndex: 1
      )

    saveServers: ->
      @model.set 'serversModified', true
      @setModelFromGUI()

    setModelFromGUI: ->
      # We don't want to change the active server if we are logged in with it.
      if not @loggedIn()
        selectedActiveServerId = @$('select[name=activeServer]').val()
        activeServer = @model.get('servers').get selectedActiveServerId
        @model.set 'activeServer', activeServer
      @serversView.setCollectionFromGUI()
      @model.save()

    keydownBigButton: (event) ->
      if event.which is 13
        @$(event.currentTarget).click()

    keydownJQueryThemeImageContainer: (event) ->
      if event.which is 13
        @$(event.currentTarget).click()

    initialize: ->
      @serversView = new ServersView
        collection: @model.get('servers')
        serverTypes: @model.get('serverTypes')
        bodyVisible: true
      @activeServerView = new ActiveServerView
        model: @model
        tooltipPosition:
          my: "right-100 center"
          at: "left center"
          collision: "flipfit"
        width: 500
      @oldApplicationSettingsCollection = new OLDApplicationSettingsCollection()

    listenToEvents: ->
      @stopListening()
      @undelegateEvents()
      @listenTo Backbone, 'activateServer', @activateServer
      @listenTo Backbone, 'removeServerView', @setModelFromGUI
      @listenTo Backbone, 'saveServers', @saveServers
      @listenTo Backbone, "addOldApplicationSettingsSuccess",
        @addOLDApplicationSettingsSuccess
      @listenToOLDApplicationSettingsCollection()
      @delegateEvents()

    addOLDApplicationSettingsSuccess: (model) ->
      console.log 'the general app settings view knows that a new OLD app
        settings was successfully created.'

    # Note the strange spellings of the events triggered here; just go along
    # with it ...
    listenToOLDApplicationSettingsCollection: ->
      @listenTo Backbone, 'fetchOldApplicationSettingsesEnd',
        @fetchOLDApplicationSettingsEnd
      @listenTo Backbone, 'fetchOldApplicationSettingsesStart',
        @fetchOLDApplicationSettingsStart
      @listenTo Backbone, 'fetchOldApplicationSettingsesSuccess',
        @fetchOLDApplicationSettingsSuccess
      @listenTo Backbone, 'fetchOldApplicationSettingsesFail',
        @fetchOLDApplicationSettingsFail

    render: (taskId) ->
      @html()
      @renderServersView()
      @renderActiveServerView()
      @matchHeights()
      @guify()
      @listenToEvents()
      Backbone.trigger 'longTask:deregister', taskId
      @fixRoundedBorders()
      @$('.application-settings-interfaces').hide()
      @hideAllSettingsButton()
      @$('.big-button').first().focus()
      @$('#dative-page-body').scroll => @closeAllTooltips()
      @

    renderServersView: ->
      @serversView.setElement @$('div.servers-collection').first()
      @serversView.render()
      @rendered @serversView

    renderActiveServerView: ->
      @activeServerView.setElement @$('div.active-server').first()
      @activeServerView.render()
      @rendered @activeServerView

    html: ->
      try
        activeJQueryUIThemeHumanReadable =
          (x for x in @model.get('jQueryUIThemes') \
          when x[0] is @model.get('activeJQueryUITheme'))[0][1]
      catch
        activeJQueryUIThemeHumanReadable =
          @model.get('activeJQueryUITheme')
      params = _.extend(
        {
          headerTitle: 'Application Settings'
          activeJQueryUIThemeHumanReadable: activeJQueryUIThemeHumanReadable
          loggedIn: @loggedIn()
        },
        @model.attributes
      )
      @$el.html @template(params)

    guify: ->
      @$('.big-button')
        .css 'border-color', @constructor.jQueryUIColors().defBo
        .attr 'tabindex', 0
        .tooltip()
      @$('.button-container-left button,.button-container-right button')
        .button()
        .tooltip()
      @$('.jquery-theme-image-container')
        .css 'border-color', @constructor.jQueryUIColors().defBo
        .tooltip position: @tooltipPositionLeft('-20')

    activateServer: (id) ->
      @$('select[name=activeServer]')
        .val(id)
        .selectmenu('refresh')
      @setModelFromGUI()

    # Change the jQuery UI CSS Theme
    changeJQueryUITheme: (event) ->
      try
        themeName =
          (x for x in event.currentTarget.className.split(/\s+/) \
          when @utils.startsWith(x, 'theme-'))[0][6...]
      catch
        console.log 'Error occured while attempting to to change the jQuery
          theme'
        return
      @$('.jquery-theme-image-container')
        .removeClass 'ui-state-highlight'
      @$(event.currentTarget).addClass 'ui-state-highlight'
      @model.set 'activeJQueryUITheme', themeName
      @model.save()
      Backbone.trigger 'applicationSettings:changeTheme'

    showSettingsList: ->
      @$('.application-settings-big-buttons').show()

    hideSettingsList: ->
      @$('.application-settings-big-buttons').hide()

    showInterfaceContainer: ->
      @$('.application-settings-interfaces').show()

    hideInterfaceContainer: ->
      @$('.application-settings-interfaces').hide()

    hideInterfaces: ->
      @$('.application-settings-interface').hide()

    showOnlySettingsList: ->
      @hideInterfaceContainer()
      @hideAllSettingsButton()
      @showSettingsList()

    hideAllSettingsButton: ->
      @$('button.all-settings').hide()

    showAllSettingsButton: ->
      @$('button.all-settings').show()

    showOnlyInterfaces: ->
      @hideSettingsList()
      @showAllSettingsButton()
      @showInterfaceContainer()

    showServersInterface: ->
      @showOnlyInterfaces()
      @hideInterfaces()
      @$('.servers-interface').show()

    showAppearanceInterface: ->
      @showOnlyInterfaces()
      @hideInterfaces()
      @$('.appearance-interface').show()

    showServerSettingsInterface: ->
      @showOnlyInterfaces()
      @hideInterfaces()
      if globals.unicodeCharMap
        @oldApplicationSettingsCollection.fetchResources()
      else
        @fetchUnicodeData(=> @oldApplicationSettingsCollection.fetchResources())

    fetchOLDApplicationSettingsEnd: ->
      @$('.application-settings-interfaces').spin false

    fetchOLDApplicationSettingsStart: ->
      @$('.application-settings-interfaces').spin @spinnerOptions()

    spinnerOptions: ->
      options = super
      options.top = '5%'
      options.left = '5%'
      options.color = @constructor.jQueryUIColors().defCo
      options

    fetchOLDApplicationSettingsFail: ->
      console.log 'Failed to fetch OLD application settings'

    fetchOLDApplicationSettingsSuccess: ->
      @$('.server-settings-interface').show()
      if @oldApplicationSettingsCollection.length > 0
        lastModel = @oldApplicationSettingsCollection
          .at(@oldApplicationSettingsCollection.length - 1)
      else
        lastModel = new OLDApplicationSettingsModel()
      @oldApplicationSettingsResourceView =
        new OLDApplicationSettingsResourceView model: lastModel
      @oldApplicationSettingsResourceView
        .setElement @$('.server-settings-interface').first()
      @oldApplicationSettingsResourceView.render()
      @rendered @oldApplicationSettingsResourceView

    loggedIn: -> @model.get 'loggedIn'

    # The special `onClose` event is called by `close` in base.coffee upon close
    onClose: ->
      @$('div#dative-page-body').first().unbind 'scroll'

