define [
  'backbone'
  './base'
  './mainmenu'
  './progress-widget'
  './notifier'
  './login-dialog'
  './register-dialog'
  './application-settings'
  './pages'
  './form-add'
  './forms'
  './../models/application-settings'
  './../models/form'
  './../collections/forms'
  './../templates/app'
], (Backbone, BaseView, MainMenuView, ProgressWidgetView,
  NotifierView, LoginDialogView, RegisterDialogView, ApplicationSettingsView,
  PagesView, FormAddView, FormsView, ApplicationSettingsModel, FormModel,
  FormsCollection, appTemplate) ->

  # App View
  # --------
  #
  #
  # This is the spine of the application. Only one AppView object is created
  # and it controls the creation and rendering of all of the subviews that
  # control the content in the body of the page.

  class AppView extends BaseView

    template: appTemplate
    el: '#dative-client-app'

    initialize: (options) ->

      # console.log 'THESE ARE THE APPLICATION SETTINGS DEFAULTS'
      # console.log JSON.stringify(ApplicationSettingsModel::defaults(), undefined, 2)

      # Allowing an app settings model in the options facilitates testing.
      if options?.applicationSettings
        @applicationSettings = options.applicationSettings
      else
        @applicationSettings = new ApplicationSettingsModel()
        # console.log 'applicationSettings instance with defaults'
        # console.log JSON.stringify(@applicationSettings.toJSON(), undefined, 2)
        #@applicationSettings.fetch()

      @mainMenuView = new MainMenuView model: @applicationSettings
      @loginDialog = new LoginDialogView model: @applicationSettings
      @registerDialog = new RegisterDialogView model: @applicationSettings
      @progressWidget = new ProgressWidgetView()
      @notifier = new NotifierView(@applicationSettings)

      @listenTo @mainMenuView, 'request:pages', @showPagesView
      @listenTo @mainMenuView, 'request:formAdd', @showFormAddView
      @listenTo @mainMenuView, 'request:formsBrowse', @showFormsView
      @listenTo @mainMenuView, 'request:openLoginDialogBox', @toggleLoginDialog
      @listenTo @mainMenuView, 'request:openRegisterDialogBox', @toggleRegisterDialog
      @listenTo @loginDialog, 'request:openRegisterDialogBox', @toggleRegisterDialog
      @listenTo @mainMenuView, 'request:applicationSettings',
        @showApplicationSettingsView

      @render()

    render: ->
      @$el.html @template()
      @mainMenuView.setElement(@$('#mainmenu')).render()
      @loginDialog.setElement(@$('#login-dialog-container')).render()
      @registerDialog.setElement(@$('#register-dialog-container')).render()
      @progressWidget.setElement(@$('#progress-widget-container')).render()
      @notifier.setElement @$('#notifier-container')
      @rendered @mainMenuView
      @rendered @loginDialog
      @rendered @registerDialog
      @rendered @progressWidget
      @rendered @notifier # Notifier self-renders but we register it as rendered anyways so that we can clean up after it if `.close` is ever called

      # FieldDB stuff commented out until it can be better incorporated
      # FieldDB.FieldDBObject.application = @applicationSettings
      # FieldDB.FieldDBObject.application.currentFieldDB = new FieldDB.Corpus()
      # FieldDB.FieldDBObject.application.currentFieldDB.loadOrCreateCorpusByPouchName("jrwdunham-firstcorpus")
      # FieldDB.FieldDBObject.application.currentFieldDB.url = FieldDB.FieldDBObject.application.currentFieldDB.BASE_DB_URL

      @matchWindowDimensions()

    # Size the #appview div relative to the window size
    matchWindowDimensions: ->
      @$('#appview').css height: $(window).height() - 50
      $(window).resize =>
        @$('#appview').css height: $(window).height() - 50

    # When a view closes, it's good to be able to keep track of
    # its focused element so that it can be returned to a past state.
    _rememberFocusedElement: ->
      focusedElement = $(document.activeElement)
      #focusedElement = @$ ':focus'
      if focusedElement
        focusedElementId = focusedElement.attr 'id'
        if focusedElementId
          @_visibleView?.focusedElementId = focusedElementId
        else if /ms-list/.test focusedElement.attr('class')
          @_visibleView?.focusedElementId = 'ms-tags .ms-list'
        else
          console.log 'focused element has no id' if AppView.debugMode

    _closeVisibleView: ->
      @_rememberFocusedElement()
      if @_visibleView
        @_visibleView.close()
        @closed @_visibleView

    showFormAddView: ->
      @_closeVisibleView()
      if not @_formAddView
        @_formAddView = new FormAddView(model: new FormModel())
      @_visibleView = @_formAddView
      @_renderVisibleView()

    showApplicationSettingsView: ->
      @_closeVisibleView()
      if not @_applicationSettingsView
        @_applicationSettingsView = new ApplicationSettingsView(
          model: @applicationSettings)
      @_visibleView = @_applicationSettingsView
      @_renderVisibleView()

    showFormsView: ->
      @_closeVisibleView()
      if not @_formsView
        @_formsView = new FormsView
          collection: new FormsCollection()
          applicationSettings: @applicationSettings
      @_visibleView = @_formsView
      @_renderVisibleView()

    showPagesView: ->
      @_closeVisibleView()
      if not @_pagesView
        @_pagesView = new PagesView()
      @_visibleView = @_pagesView
      @_renderVisibleView()

    _renderVisibleView: ->
      @_visibleView.setElement @$('#appview')
      @_visibleView.render()
      @rendered @_visibleView

    # Open/close the login dialog box
    toggleLoginDialog: ->
      Backbone.trigger 'loginDialog:toggle'

    # Open/close the register dialog box
    toggleRegisterDialog: ->
      Backbone.trigger 'registerDialog:toggle'

