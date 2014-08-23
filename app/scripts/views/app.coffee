define [
  'jquery'
  'lodash'
  'backbone'
  'templates'
  'views/base'
  'views/mainmenu'
  'views/progress-widget'
  'views/notifier'
  'views/login-dialog'
  'views/application-settings'
  'views/pages'
  'views/form-add'
  'views/forms'
  'models/application-settings'
  'models/form'
  'collections/forms'
], ($, _, Backbone, JST, BaseView, MainMenuView, ProgressWidgetView,
  NotifierView, LoginDialogView, ApplicationSettingsView, PagesView,
  FormAddView, FormsView, ApplicationSettingsModel, FormModel,
  FormsCollection) ->

  # App View
  # --------
  #
  # This is the spine of the application. There is only one of these and it
  # controls the creation and rendering of all of the subviews that control
  # the content in the body of the page.

  class AppView extends BaseView

    template: JST['app/scripts/templates/app.ejs']
    el: '#dative-client-app'

    initialize: ->

      @applicationSettings = new ApplicationSettingsModel()
      @mainMenuView = new MainMenuView(model: @applicationSettings)
      @loginDialog = new LoginDialogView(model: @applicationSettings)
      @progressWidget = new ProgressWidgetView()
      @notifier = new NotifierView()

      @listenTo @mainMenuView, 'request:pages', @showPagesView
      @listenTo @mainMenuView, 'request:formAdd', @showFormAddView
      @listenTo @mainMenuView, 'request:formsBrowse', @showFormsView
      @listenTo @mainMenuView, 'request:openLoginDialogBox', @toggleLoginDialog
      @listenTo @mainMenuView, 'request:applicationSettings', @showApplicationSettingsView

      @render()

    render: ->

      @$el.html @template()
      @mainMenuView.setElement('#mainmenu').render()
      @loginDialog.render()
      @progressWidget.setElement('#progress-widget-container').render()
      @notifier.setElement '#notifier-container'

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
      if focusedElement
        focusedElementId = focusedElement.attr('id')
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
        @_formsView = new FormsView(collection: new FormsCollection())
      @_visibleView = @_formsView
      @_renderVisibleView()

    showPagesView: ->
      @_closeVisibleView()
      if not @_pagesView
        @_pagesView = new PagesView()
      @_visibleView = @_pagesView
      @_renderVisibleView()

    _renderVisibleView: ->
      @_visibleView.setElement '#appview'
      @_visibleView.render()
      @rendered @_visibleView

    # Open/close the login dialog box
    toggleLoginDialog: ->
      if @loginDialog.isOpen() then @loginDialog.close() else @loginDialog.open()

