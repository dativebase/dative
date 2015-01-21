define [
  'backbone'
  './../routes/router'
  './base'
  './mainmenu'
  './progress-widget'
  './notifier'
  './login-dialog'
  './register-dialog'
  './alert-dialog'
  './application-settings'
  './pages'
  './home'
  './form-add'
  './forms-search'
  './forms'
  './corpora'
  './../models/application-settings'
  './../models/form'
  './../collections/application-settings'
  './../templates/app'
], (Backbone, Workspace, BaseView, MainMenuView, ProgressWidgetView,
  NotifierView, LoginDialogView, RegisterDialogView, AlertDialogView,
  ApplicationSettingsView, PagesView, HomePageView, FormAddView,
  FormsSearchView, FormsView, CorporaView, ApplicationSettingsModel, FormModel,
  ApplicationSettingsCollection, appTemplate) ->

  # App View
  # --------
  #
  # This is the spine of the application. Only one AppView object is created
  # and it controls the creation and rendering of all of the subviews that
  # control the content in the body of the page.

  class AppView extends BaseView

    template: appTemplate
    el: '#dative-client-app'

    initialize: (options) ->

      @router = new Workspace()
      @getApplicationSettings options

      @mainMenuView = new MainMenuView model: @applicationSettings
      @loginDialog = new LoginDialogView model: @applicationSettings
      @registerDialog = new RegisterDialogView model: @applicationSettings
      @alertDialog = new AlertDialogView model: @applicationSettings
      @progressWidget = new ProgressWidgetView()
      @notifier = new NotifierView(@applicationSettings)

      @listenTo @mainMenuView, 'request:home', @showHomePageView
      @listenTo @mainMenuView, 'request:applicationSettings', @showApplicationSettingsView
      @listenTo @mainMenuView, 'request:openLoginDialogBox', @toggleLoginDialog
      @listenTo @mainMenuView, 'request:openRegisterDialogBox', @toggleRegisterDialog
      @listenTo @mainMenuView, 'request:corporaBrowse', @showCorporaView
      @listenTo @mainMenuView, 'request:formAdd', @showFormAddView
      @listenTo @mainMenuView, 'request:formsBrowse', @showFormsView
      @listenTo @mainMenuView, 'request:formsSearch', @showFormsSearchView
      @listenTo @mainMenuView, 'request:pages', @showPagesView

      @listenTo @router, 'route:home', @showHomePageView
      @listenTo @router, 'route:applicationSettings', @showApplicationSettingsView
      @listenTo @router, 'route:openLoginDialogBox', @toggleLoginDialog
      @listenTo @router, 'route:openRegisterDialogBox', @toggleRegisterDialog
      @listenTo @router, 'route:corporaBrowse', @showCorporaView
      @listenTo @router, 'route:formAdd', @showFormAddView
      @listenTo @router, 'route:formsBrowse', @showFormsView
      @listenTo @router, 'route:formsSearch', @showFormsSearchView
      @listenTo @router, 'route:pages', @showPagesView

      @listenTo @loginDialog, 'request:openRegisterDialogBox', @toggleRegisterDialog
      @listenTo Backbone, 'loginSuggest', @openLoginDialogWithDefaults
      @listenTo Backbone, 'authenticate:success', @authenticateSuccess
      @listenTo Backbone, 'logout:success', @logoutSuccess
      @listenTo Backbone, 'useFieldDBCorpus', @useFieldDBCorpus
      @listenTo Backbone, 'useFieldDBCorpus', @useFieldDBCorpus
      @listenTo Backbone, 'applicationSettings:changeTheme', @changeTheme

      @render()

      if @applicationSettings.get('activeJQueryUITheme') isnt 'cupertino'
        @changeTheme()

      Backbone.history.start()
      @showHomePageView()

    events:
      'click': 'bodyClicked'

    render: ->
      @$el.html @template()

      @mainMenuView.setElement(@$('#mainmenu')).render()
      @loginDialog.setElement(@$('#login-dialog-container')).render()
      @registerDialog.setElement(@$('#register-dialog-container')).render()
      @alertDialog.setElement(@$('#alert-dialog-container')).render()
      @progressWidget.setElement(@$('#progress-widget-container')).render()
      @notifier.setElement @$('#notifier-container')

      @rendered @mainMenuView
      @rendered @loginDialog
      @rendered @registerDialog
      @rendered @alertDialog
      @rendered @progressWidget
      @rendered @notifier # Notifier self-renders but we register it as rendered anyways so that we can clean up after it if `.close` is ever called

      # FieldDB stuff commented out until it can be better incorporated
      # FieldDB.FieldDBObject.application = @applicationSettings
      # FieldDB.FieldDBObject.application.currentFieldDB = new FieldDB.Corpus()
      # FieldDB.FieldDBObject.application.currentFieldDB.loadOrCreateCorpusByPouchName("jrwdunham-firstcorpus")
      # FieldDB.FieldDBObject.application.currentFieldDB.url = FieldDB.FieldDBObject.application.currentFieldDB.BASE_DB_URL

      @matchWindowDimensions()

    bodyClicked: ->
      Backbone.trigger 'bodyClicked' # Mainmenu superclick listens for this

    useFieldDBCorpus: (corpusId) ->
      # TODO @jrwdunham: backbone-relational-ify this!:
      currentlyActiveFieldDBCorpus = @applicationSettings
        .get 'activeFieldDBCorpus'
      fieldDBCorporaCollection = @applicationSettings.get(
        'fieldDBCorporaCollection')
      newActiveFieldDBCorpus = fieldDBCorporaCollection.findWhere
        pouchname: corpusId
      @applicationSettings.set 'activeFieldDBCorpus', newActiveFieldDBCorpus

      if currentlyActiveFieldDBCorpus is newActiveFieldDBCorpus
        @showFormsView fieldDBCorpusHasChanged: false
      else
        @showFormsView fieldDBCorpusHasChanged: true

    logoutSuccess: ->
      @closeVisibleView()
      @corporaView = null
      @showHomePageView()

    activeServerType: ->
      try
        @applicationSettings.get('activeServer').get 'type'
      catch
        null

    authenticateSuccess: ->
      activeServerType = @activeServerType()
      switch activeServerType
        when 'FieldDB' then @showCorporaView()
        when 'OLD' then @showFormsView()
        else console.log 'Error: you logged in to a non-FieldDB/non-OLD server (?).'

    # Set `@applicationSettings` and `@applicationSettingsCollection`
    getApplicationSettings: (options) ->
      @applicationSettingsCollection = new ApplicationSettingsCollection()
      # Allowing an app settings model in the options facilitates testing.
      if options?.applicationSettings
        @applicationSettings = options.applicationSettings
        @applicationSettingsCollection.add @applicationSettings
      else
        @applicationSettingsCollection.fetch()
        if @applicationSettingsCollection.length
          @applicationSettings = @applicationSettingsCollection.at 0
        else
          @applicationSettings = new ApplicationSettingsModel()
          @applicationSettingsCollection.add @applicationSettings

    # Size the #appview div relative to the window size
    matchWindowDimensions: ->
      @$('#appview').css height: $(window).height() - 50
      $(window).resize =>
        @$('#appview').css height: $(window).height() - 50

    renderVisibleView: (taskId=null) ->
      @visibleView.setElement @$('#appview')
      @visibleView.render taskId
      @rendered @visibleView

    closeVisibleView: ->
      if @visibleView
        @visibleView.close()
        @closed @visibleView

    loggedIn: -> @applicationSettings.get 'loggedIn'

    ############################################################################
    # Methods for showing the main "pages" of Dative                           #
    ############################################################################

    showFormAddView: ->
      if not @loggedIn() then return
      if @formAddView and @visibleView is @formAddView then return
      @router.navigate 'form-add'
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'Opening form add view', taskId
      @closeVisibleView()
      if not @formAddView
        @formAddView = new FormAddView(model: new FormModel())
      @visibleView = @formAddView
      @renderVisibleView taskId

    showApplicationSettingsView: ->
      if @applicationSettingsView and
      @visibleView is @applicationSettingsView then return
      @router.navigate 'application-settings'
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'Opening application settings', taskId
      @closeVisibleView()
      if not @applicationSettingsView
        @applicationSettingsView = new ApplicationSettingsView(
          model: @applicationSettings)
      @visibleView = @applicationSettingsView
      @renderVisibleView taskId

    showFormsView: (options) ->
      if not @loggedIn() then return
      if @formsView and @visibleView is @formsView then return
      @router.navigate 'forms-browse'
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'Opening form browse view', taskId
      @closeVisibleView()
      if @formsView
        if @activeServerType() is 'FieldDB' and options?.fieldDBCorpusHasChanged
          @formsView.close()
          @closed @formsView
          @formsView = new FormsView applicationSettings: @applicationSettings
      else
        @formsView = new FormsView applicationSettings: @applicationSettings
      @visibleView = @formsView
      @renderVisibleView taskId

    showFormsSearchView: ->
      if not @loggedIn() then return
      if @formsSearchView and @visibleView is @formsSearchView then return
      @router.navigate 'forms-search'
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'Opening form search view', taskId
      @closeVisibleView()
      if not @formsSearchView then @formsSearchView = new FormsSearchView()
      @visibleView = @formsSearchView
      @renderVisibleView taskId

    showPagesView: ->
      if not @loggedIn() then return
      if @pagesView and @visibleView is @pagesView then return
      @router.navigate 'pages'
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'Opening pages view', taskId
      @closeVisibleView()
      if not @pagesView then @pagesView = new PagesView()
      @visibleView = @pagesView
      @renderVisibleView taskId

    showHomePageView: ->
      if @homePageView and @visibleView is @homePageView then return
      @router.navigate 'home'
      @closeVisibleView()
      if not @homePageView then @homePageView = new HomePageView()
      @visibleView = @homePageView
      @renderVisibleView()

    showCorporaView: ->
      if not @loggedIn() then return
      if @corporaView and @visibleView is @corporaView then return
      @router.navigate 'corpora'
      taskId = @guid()
      Backbone.trigger 'longTask:register', 'Opening corpora view', taskId
      @closeVisibleView()
      if not @corporaView
        @corporaView = new CorporaView applicationSettings: @applicationSettings
      @visibleView = @corporaView
      @renderVisibleView taskId

    # Open/close the login dialog box
    toggleLoginDialog: ->
      Backbone.trigger 'loginDialog:toggle'

    openLoginDialogWithDefaults: (username, password) ->
      @loginDialog.dialogOpenWithDefaults
        username: username
        password: password

    # Open/close the register dialog box
    toggleRegisterDialog: ->
      Backbone.trigger 'registerDialog:toggle'

    # Open/close the alert dialog box
    toggleAlertDialog: ->
      Backbone.trigger 'alertDialog:toggle'

    ############################################################################
    # Change the jQuery UI CSS Theme
    ############################################################################

    changeTheme: (event) ->

      # This is harder than it might at first seem.
      # Method:
      # 1. get new CSS URL from selectmenu
      # 2. remove the current jQueryUI CSS <link>
      # 3. add a new jQueryUI CSS <link> with the new URL in its `href`
      # 4. ***CRUCIAL:*** when <link> `load` event fires, we ...
      # 5. get `BaseView.constructor` to refresh its `_jQueryUIColors`, which ...
      # 6. triggers a Backbone event indicating that the jQueryUI theme has changed, which ...
      # 7. causes `MainMenuView` to re-render.
      #
      # WARN: works for me on Mac with FF, Ch & Sa. Unsure of
      # cross-platform/browser support. May want to do feature detection and
      # employ a mixture of strategies 1-4.

      themeName = @applicationSettings.get 'activeJQueryUITheme'
      # TODO: this URL stuff should be in model
      newJQueryUICSSURL = "http://code.jquery.com/ui/1.11.2/themes/#{themeName}/jquery-ui.min.css"
      $jQueryUILinkElement = $('#jquery-ui-css')
      $jQueryUILinkElement.remove()
      $jQueryUILinkElement.attr href: newJQueryUICSSURL
      linkHTML = $jQueryUILinkElement.get(0).outerHTML
      $('#font-awesome-css').after linkHTML
      outerCallback = =>
        innerCallback = =>
          Backbone.trigger 'application-settings:jQueryUIThemeChanged'
        @constructor.refreshJQueryUIColors innerCallback
      @listenForLinkOnload outerCallback

      # Remaining TODOs:
      # 1. persist theme settings to localhost
      # 2. create a default in application settings model
      # 3. disable this feature when there is no Internet connection
      # 4. focus highlight doesn't match on login dialog (probably because it
      #    should be re-rendered after theme change)
      # 5. Gap between rounded borders and container fill. See
      #    http://w3facility.org/question/jquery-ui-how-to-remove-gap-at-each-rounded-corner-of-accordions/

    # Four strategies for detecting that a new CSS <link> has loaded.
    ############################################################################
    #
    # See http://www.phpied.com/when-is-a-stylesheet-really-loaded/

    # strategy #1
    listenForLinkOnload: (callback) ->
      link = document.getElementById 'jquery-ui-css'
      link.onload = -> callback()

    # strategy #2
    addEventListenerToLink: (callback) ->
      link = document.getElementById 'jquery-ui-css'
      eventListener = -> callback()
      if link.addEventListener
        link.addEventListener 'load', eventListener, false

    # strategy #3
    listenForReadyStateChange: (callback) ->
      link = document.getElementById 'jquery-ui-css'
      link.onreadystatechange = ->
        state = link.readyState
        if state is 'loaded' or state is 'complete'
          link.onreadystatechange = null
          callback()

    # strategy #4
    checkForChangeInDocumentStyleSheets: (callback) ->
      cssnum = document.styleSheets.length
      func = ->
        if document.styleSheets.length > cssnum
          callback()
          clearInterval ti
      ti = setInterval func, 10

