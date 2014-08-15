define [
  'jquery'
  'lodash'
  'backbone'
  'templates'
  'views/base'
  'views/login-dialog'
  'views/application-settings'
  'views/pages'
  'views/form-add'
  'views/forms'
  'models/application-settings'
  'models/form'
  'collections/forms'
  'jqueryui'
  'superfish'
  'supersubs'
  'sfjquimatch'
], ( $, _, Backbone, JST, BaseView, LoginDialogView, ApplicationSettingsView,
  PagesView, FormAddView, FormsView, ApplicationSettingsModel, FormModel,
  FormsCollection) ->


  # Main Menu View
  # This is the spine of the application. There is only one of these and it
  # controls the creation and rendering of all of the subviews that control
  # the content in the body of the page.

  class MainMenuView extends BaseView

    tagName: 'div'
    className: 'mainmenu'
    template: JST['app/scripts/templates/mainmenu.ejs']

    initialize: ->

      # One login dialog
      @loginDialog = new LoginDialogView()
      @loginDialog.render()

      # One application settings object
      # TODO: fetch this from localStorage, if exists
      @applicationSettings = new ApplicationSettingsModel()

      @listenTo @, 'request:pages', @showPagesView
      @listenTo @, 'request:formAdd', @showFormAddView
      @listenTo @, 'request:formsBrowse', @showFormsView
      @listenTo @, 'request:openLoginDialogBox', @toggleLoginDialog
      @listenTo @, 'request:applicationSettings', @showApplicationSettingsView
      @listenTo @applicationSettings, 'change:loggedIn', @loggedInChanged

    # applicationSettings.loggedIn has changed: change the main menu accordingly
    loggedInChanged: ->
      @_refreshLoginButton()
      if @applicationSettings and @loginDialog.isOpen()
        @loginDialog.close()

    events:
      'click a.old-authenticated': 'toggleLoginDialog'

    render: ->
      # Match jQuery UI colors and insert menu template.
      @$el.css(MainMenuView.jQueryUIColors.def).html @template()

      # Superfish transmogrifies menu
      @superfishify()

      # Login button
      @_refreshLoginButton()

      # Vivify menu buttons
      @bindClickToEventTrigger()

      # Keyboard shortcuts
      @shortcutConfig()

    # When a view closes, it's good to be able to keep track of
    # its focused element so that it can be returned to a past state.
    _rememberFocusedElement: ->
      console.log 'HERE I SET FOCUSED ELEMENT ID IN MAIN MENU'
      focusedElement = $(document.activeElement)
      if focusedElement
        focusedElementId = focusedElement.attr('id')
        if focusedElementId
          @_visibleView?.focusedElementId = focusedElementId
        else if /ms-list/.test focusedElement.attr('class')
          @_visibleView?.focusedElementId = 'ms-tags .ms-list'
        else
          console.log 'focused element has no id' if MainMenuView.debugMode?

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

    # Superfish jQuery plugin turns mainmenu <ul> into a menubar
    superfishify: ->
      @$('.sf-menu').supersubs(minWidth: 12, maxWidth: 27, extraWidth: 2)
        .superfish(autoArrows: false)
        .superfishJQueryUIMatch(MainMenuView.jQueryUIColors)

    # configureMenuEvents
    # 1. bind menu item click to data-event trigger
    # 2. bind data-shortcut keypress event to data-event trigger
    # 3.
    # Bind menu item clicks to trigger of the data-event attr's event
    bindClickToEventTrigger: ->
      mainmenuView = @
      @$('[data-event]').each ->
        $(@).click ->
          console.log "clicked #{$(@).attr('data-event')}" if MainMenuView?.debugMode
          mainmenuView.trigger $(@).attr('data-event')

    # Configure keyboard shortcuts
    # 1. Bind shortcut keystrokes to the appropriate events.
    # 2. Modify the menu items so that shortcuts abbreviations are displayed.
    shortcutConfig: ->
      mainmenuView = @
      $('[data-shortcut][data-event]').each ->
        event = $(@).attr 'data-event'
        shortcut = $(@).attr 'data-shortcut'
        mainmenuView.bindShortcutToEventTrigger shortcut, event
        $(@).append $('<span>').addClass('float-right').text(
          mainmenuView.getShortcutAbbreviation(shortcut))

    # Bind keyboard shortcut to event to triggering of event
    bindShortcutToEventTrigger: (shortcutString, eventName) ->
      # Map for 'ctrl+A' would be {ctrlKey: true, shortcutKey: 65}
      map = @getShortcutMap shortcutString
      mainmenuView = @

      # Bind the keydown event to the function
      $(document).keydown (event) ->
        if event.ctrlKey is map.ctrlKey and
        event.altKey is map.altKey and
        event.shiftKey is map.shiftKey and
        event.which is map.shortcutKey
          console.log "keyboard shortcut #{eventName}" if MainMenuView.debugMode?
          event.preventDefault()
          event.stopPropagation()
          mainmenuView.trigger eventName

    # Return a shortcut object from a shortcut string.
    # Shortcut Map for a shortcut string like 'ctrl+A' would be
    # {ctrlKey: true, shortcutKey: 65}
    getShortcutMap: (shortcutString) ->
      shortcutArray = shortcutString.split '+'
      # Returns the codes for the arrow symbols or else the character code
      getShortcutCode = (shortcutAsString) ->
        switch shortcutAsString
          when 'rArrow' then 39
          when 'lArrow' then 37
          when 'uArrow' then 38
          when 'dArrow' then 40
          else shortcutAsString.toUpperCase().charCodeAt 0

      ctrlKey: 'ctrl' in shortcutArray
      altKey: 'alt' in shortcutArray
      shiftKey: 'shift' in shortcutArray
      shortcutKey: getShortcutCode shortcutArray.pop()

    # Return a shortcut abbreviation from a shortcuts string.
    # Use unicode symbols for modifier keys.
    # E.g., "ctrl+a" => "\u2303A", "alt+rArrow" => "\u2325\u2192"
    getShortcutAbbreviation: (shortcutString) ->
      shortcutArray = shortcutString.split '+'
      # Return an abbreviation of the shortcut key
      getShortcutKeyAbbrev = (shortcutString) ->
        switch shortcutString
          when 'rArrow' then '\u2192'
          when 'lArrow' then '\u2190'
          when 'uArrow' then '\u2191'
          when 'dArrow' then '\u2193'
          else shortcutString[0].toUpperCase()

      # Get meta characters and shortcut key in an ordered list
      [
        if 'ctrl' in shortcutArray then '\u2303' else ''
        if 'alt' in shortcutArray then '\u2325' else ''
        if 'shift' in shortcutArray then '\u21E7' else ''
        getShortcutKeyAbbrev shortcutArray.pop()
      ].join ''

    # Initialize login/logout icon/button
    _refreshLoginButton: ->
      text = 'Login'
      icon = 'ui-icon-locked'
      title = 'login'
      if @applicationSettings.get 'loggedIn'
        text = 'Logout'
        icon = 'ui-icon-unlocked'
        title = 'logout'
      @$('a.old-authenticated').text(text).attr('title', title)
        .button({icons: {primary: icon}, text: false})
        .css('border-color', MainMenuView.jQueryUIColors.defBa)

    # Open/close the login dialog box
    toggleLoginDialog: ->
      if @loginDialog.isOpen() then @loginDialog.close() else @loginDialog.open()

