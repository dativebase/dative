define [
  'backbone'
  './base'
  './servers'
  './active-server'
  './old-application-settings-resource'
  './old-application-settings-add-widget'
  './input-validation'
  './keyboard-preference-set'
  './../models/old-application-settings'
  './../collections/old-application-settings'
  './../utils/globals'
  './../templates/application-settings'
], (Backbone, BaseView, ServersView, ActiveServerView,
  OLDApplicationSettingsResourceView, OLDApplicationSettingsAddWidgetView,
  InputValidationView, KeyboardPreferenceSetView, OLDApplicationSettingsModel,
  OLDApplicationSettingsCollection, globals, applicationSettingsTemplate) ->


  class MyOLDApplicationSettingsAddWidgetView extends OLDApplicationSettingsAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: [
      'object_language_name'
      'object_language_id'

      'metalanguage_name'
      'metalanguage_id'
      # 'metalanguage_inventory'

      'unrestricted_users'
    ]

    spacerIndices: -> [2, 4]


  class MyOLDApplicationSettingsResourceView extends OLDApplicationSettingsResourceView

    resourceAddWidgetView: MyOLDApplicationSettingsAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: [
      'object_language_name'
      'object_language_id'

      'metalanguage_name'
      'metalanguage_id'
      # 'metalanguage_inventory' # This isn't used right now, and it's just
      # confusing.

      'unrestricted_users'

      'datetime_modified'
    ]

    spacerIndices: -> [2, 4, 5]


  # Application Settings View
  # -------------------------
  #
  # View for viewing and modifying the settings of this Dative application.
  # These settings are currently divided into 5 sections/parts:
  #
  # 1. Servers: the servers that we expect to be connecting to via this Dative
  #    application. These are persisted locally (in LocalStorage) but Dative
  #    also sends us an array of them in servers.json which the user can merge
  #    into their own list of servers, if they want.
  #
  # 2. Server Settings: this is an interface to the settings of the OLD server
  #    that the user is currently logged into. It allows the user to set/change
  #    the object language and metalanguage name and ISO 639-3 Id values, as
  #    well as the set of "unrestricted" users.
  #
  # 3. Input Validation: an interface to the settings (of the OLD that the user
  #    is logged in to) that deal with what kind of values users can enter into
  #    specific form fields.
  #
  # 4. Keyboard Preferences: client-side settings that allow users to assign
  #    specific keyboard resources to particular form fields. E.g., an IPA
  #    keyboard to the phonetic transcription field.
  #
  # 5. Appearance: choose the jQueryUI theme that you want. Choice is persisted
  #    in the app-wide `ApplicationSettingsModel` instance in LocalStorage
  #    (same one that is used to persist the server settings in (1)).

  class ApplicationSettingsView extends BaseView

    tagName: 'div'
    template: applicationSettingsTemplate

    events:
      'click button.all-settings': 'showOnlySettingsList'
      'click .big-button.servers': 'showServersInterface'
      'click .big-button.appearance': 'showAppearanceInterface'
      'click .big-button.server-settings': 'showServerSettingsInterface'
      'click .big-button.input-validation': 'showInputValidationInterface'
      'click .big-button.keyboard-preferences': 'showKeyboardPreferencesInterface'
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
      @viewToDisplayOLDApplicationSettings =
        'OLDApplicationSettingsResourceView'
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
      @$('.dative-page-body').first().scroll => @closeAllTooltips()
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

    showKeyboardPreferencesInterface: ->
      # We make sure we have the Unicode character map object before rendering
      # the keyboard preferences interface since the referenced keyboard views
      # won't render without it.
      if not globals.unicodeCharMap
        @fetchUnicodeData(=> @showKeyboardPreferencesInterface())
        return
      @showOnlyInterfaces()
      @hideInterfaces()
      if not @keyboardPreferenceSetView
        @initializeKeyboardPreferenceSetView()
      @renderKeyboardPreferenceSetView()
      @$('.keyboard-preferences-interface').show()

    renderKeyboardPreferenceSetView: ->
      @keyboardPreferenceSetView.setElement(
        @$('.keyboard-preferences-interface').first())
      @keyboardPreferenceSetView.render()
      @rendered @keyboardPreferenceSetView

    initializeKeyboardPreferenceSetView: ->
      keyboardPreferenceSetModel =
        globals.applicationSettings.get 'keyboardPreferenceSet'
      @keyboardPreferenceSetView =
        new KeyboardPreferenceSetView model: keyboardPreferenceSetModel

    showServerSettingsInterface: ->
      @viewToDisplayOLDApplicationSettings =
        'OLDApplicationSettingsResourceView'
      @showOnlyInterfaces()
      @hideInterfaces()
      if globals.unicodeCharMap
        @oldApplicationSettingsCollection.fetchResources()
      else
        @fetchUnicodeData(=> @oldApplicationSettingsCollection.fetchResources())

    showInputValidationInterface: ->
      @viewToDisplayOLDApplicationSettings = 'InputValidationView'
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
      if @viewToDisplayOLDApplicationSettings is 'InputValidationView'
        @renderInputValidationView lastModel
      else
        @renderOLDApplicationSettingsResourceView lastModel

    renderOLDApplicationSettingsResourceView: (model) ->
      @oldApplicationSettingsResourceView =
        new MyOLDApplicationSettingsResourceView model: model
      @oldApplicationSettingsResourceView
        .setElement @$('.server-settings-interface').first()
      @oldApplicationSettingsResourceView.render()
      @rendered @oldApplicationSettingsResourceView

    renderInputValidationView: (model) ->
      @inputValidationView =
        new InputValidationView model: model
      @inputValidationView
        .setElement @$('.server-settings-interface').first()
      @inputValidationView.render()
      @rendered @inputValidationView

    loggedIn: -> @model.get 'loggedIn'

    # The special `onClose` event is called by `close` in base.coffee upon close
    onClose: ->
      @$('div.dative-page-body').first().unbind 'scroll'

