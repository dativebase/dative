define [
  'jquery'
  'backbone'
  './base'
  './../templates/mainmenu'
  'superfish'
  'superclick'
  'supersubs'
  'sfjquimatch'
], ($, Backbone, BaseView, mainmenuTemplate) ->

  # Main Menu View
  # --------------
  #
  # The drop-down menu which is always at the top of a Dative application.

  class MainMenuView extends BaseView

    tagName: 'div'
    className: 'mainmenu'
    template: mainmenuTemplate

    initialize: ->
      @listenTo @model, 'change:loggedIn', @loggedInChanged
      @listenTo @model, 'change:activeFieldDBCorpus', @refreshLoggedInUser
      @listenTo Backbone, 'bodyClicked', @closeSuperclick

    loggedInChanged: ->
      @render()

    # Make certain menu items (in)active and (in)visible depending on
    # authentication status and server type.
    setActivityAndVisibility: ->
      if @model.get('loggedIn')
        @$('li.requires-authentication').not('.fielddb')
          .show()
          .find('a').removeClass 'disabled'
        if @model.get('activeServer')?.get('type') is 'FieldDB'
          @$('li.fielddb').show()
            .children('a').removeClass 'disabled'
      else
        @$('li.requires-authentication').hide()
          .children('a').addClass 'disabled'

    events:
      'click a.dative-authenticated': 'toggleLoginDialog'

    render: ->
      @$el.css(MainMenuView.jQueryUIColors.def).html @template() # match jQueryUI colors
      @setActivityAndVisibility()

      # NOTE @jrwdunham @cesine: I moved to superclick because touchscreen devices
      # don't support hover events, but apparently superfish does support touchscreen
      # devices (see http://users.tpg.com.au/j_birch/plugins/superfish/) so maybe we
      # should switch back.
      #@superfishify() # Superfish transmogrifies menu
      @superclickify() # Superclick transmogrifies menu

      @refreshLoginButton()
      @refreshLoggedInUser()
      @bindClickToEventTrigger() # Vivify menu buttons
      @keyboardShortcuts()

    # Superfish jQuery plugin turns mainmenu <ul> into a menubar
    superfishify: ->
      @$('.sf-menu').supersubs(minWidth: 12, maxWidth: 27, extraWidth: 2)
        .superfish(autoArrows: false)
        .superfishJQueryUIMatch(MainMenuView.jQueryUIColors)

    # Superclick jQuery plugin turns mainmenu <ul> into a menubar
    superclickify: ->
      @$('.sf-menu').supersubs(minWidth: 12, maxWidth: 27, extraWidth: 2)
        .superclick(autoArrows: false)
        .superfishJQueryUIMatch(MainMenuView.jQueryUIColors)

    closeSuperclick: ->
      @$('.sf-menu').superclick 'reset'

    # Menu item clicks and keyboard shortcut behaviours are all defined in the
    # data-event and data-shortcut attributes of the <li>s specified in the
    # template. The following functionality creates the appropriate bindings.

    # Bind main menu item clicks to the triggering of the appropriate events.
    bindClickToEventTrigger: ->
      @$('[data-event]').each (index, element) =>
        $(element).click (event) =>
          @$('.sf-menu').superclick('reset')
          event.stopPropagation()
          @trigger $(element).attr('data-event')

    # Configure keyboard shortcuts
    # 1. Bind shortcut keystrokes to the appropriate events.
    # 2. Modify the menu items so that shortcut abbreviations are displayed.
    keyboardShortcuts: ->
      $(document).off 'keydown'
      $('[data-shortcut][data-event]').each (index, element) =>
        if not $(element).hasClass 'disabled'
          event = $(element).attr 'data-event'
          shortcut = $(element).attr 'data-shortcut'
          @bindShortcutToEventTrigger shortcut, event
          shortcutAbbreviation = @getShortcutAbbreviation(shortcut)
          $(element).append $('<span>').addClass('float-right').html(
            @getShortcutInFixedWithSpans(shortcutAbbreviation))

    getShortcutInFixedWithSpans: (shortcut) ->
      [initial..., last] = shortcut
      "#{initial.join('')}<span class='fixed-width'>#{last}</span>"

    # Bind keyboard shortcut to triggering of event
    bindShortcutToEventTrigger: (shortcutString, eventName) ->
      # Map for 'ctrl+A' would be {ctrlKey: true, shortcutKey: 65}
      map = @getShortcutMap shortcutString

      # Bind the keydown event to the function
      $(document).keydown (event) =>
        if event.ctrlKey is map.ctrlKey and
        event.altKey is map.altKey and
        event.shiftKey is map.shiftKey and
        event.which is map.shortcutKey
          event.preventDefault()
          event.stopPropagation()
          @trigger eventName

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
          when ',' then 188
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
    refreshLoginButton: ->
      if @model.get 'loggedIn'
        @$('a.dative-authenticated')
          .attr 'title', 'logout'
          .find('i').removeClass('fa-lock').addClass('fa-unlock-alt').end()
          .button()
          .css 'border-color', MainMenuView.jQueryUIColors.defBa
          .tooltip()
      else
        @$('a.dative-authenticated')
          .attr 'title', 'login'
          .find('i').removeClass('fa-unlock-alt').addClass('fa-lock').end()
          .button()
          .css 'border-color', MainMenuView.jQueryUIColors.defBa
          .tooltip()

    # Reset the tooltip title of the logged-in user's name in the top right.
    refreshLoggedInUser: ->
      if @model.get 'loggedIn'
        username = @model.get 'username'
        activeServerName = @model.get('activeServer')?.get 'name'
        activeServerType = @model.get('activeServer')?.get 'type'
        activeFieldDBCorpus = @model.get 'activeFieldDBCorpus'
        title = ["You are logged in to the server “#{activeServerName}”",
          "as “#{username}”"].join ' '
        if activeServerType is 'FieldDB' and activeFieldDBCorpus
          title = ["#{title} and are using the corpus",
            "“#{activeFieldDBCorpus.get 'title'}”"].join ' '
        @$('.logged-in-username')
          .text username
          .attr 'title', title
          .tooltip()

    # Tell the login dialog box to toggle itself.
    toggleLoginDialog: ->
      Backbone.trigger 'loginDialog:toggle'

