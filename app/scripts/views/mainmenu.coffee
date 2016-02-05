define [
  'jquery'
  'backbone'
  './base'
  './../utils/globals'
  './../utils/keyboard-shortcuts'
  './../templates/mainmenu'
  'superclick'
  'supersubs'
], ($, Backbone, BaseView, globals, keyboardShortcuts, mainmenuTemplate) ->

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
      @listenTo @model, 'change:activeFieldDBCorpusTitle', @activeFieldDBCorpusChanged
      @listenTo @model, 'change:activeServer', @activeFieldDBCorpusChanged
      @listenTo Backbone, 'bodyClicked', @closeSuperclick
      @listenTo Backbone, 'application-settings:jQueryUIThemeChanged', @jQueryUIThemeChanged

    activeFieldDBCorpusChanged: ->
      @refreshLoggedInUser()
      @displayActiveCorpusName()

    # When an element with a `data-event` attribute is clicked, the value of
    # that attribute is the Backbone event that is triggered. This makes the
    # menu buttons work.
    triggerMenuAction: (event) ->
      @$('.sf-menu').superclick 'reset'
      event.stopPropagation()
      @trigger $(event.target).attr('data-event')

    events:

      'click [data-event]': 'triggerMenuAction'
      'click a.dative-authenticated': 'toggleLoginDialog'
      'click a.dative-help': 'toggleHelpDialog'

      'mouseenter ul.sf-menu > li > ul > li': 'mouseEnteredMenuItem'
      'mouseenter ul.sf-menu > li > ul > li > a': 'mouseEnteredMenuItem'

      'mouseleave ul.sf-menu > li > ul > li': 'mouseLeftMenuItem'
      'mouseleave ul.sf-menu > li > ul > li > a': 'mouseLeftMenuItem'

      'mousedown ul.sf-menu > li': 'mouseDownMenuItem'
      'mousedown ul.sf-menu > li > a': 'mouseDownMenuItem'
      'mousedown ul.sf-menu > li > ul > li': 'mouseDownMenuItem'
      'mousedown ul.sf-menu > li > ul > li > a': 'mouseDownMenuItem'

      'mouseup ul.sf-menu > li': 'mouseUpMenuItem'
      'mouseup ul.sf-menu > li > a': 'mouseUpMenuItem'
      'mouseup ul.sf-menu > li > ul > li': 'mouseUpMenuItem'
      'mouseup ul.sf-menu > li > ul > li > a': 'mouseUpMenuItem'

    loggedInChanged: ->
      @render()

    jQueryUIThemeChanged: ->
      @render()

    # Make certain menu items (in)active and (in)visible depending on
    # authentication status and server type.
    setActivityAndVisibility: ->
      if @model.get 'loggedIn'
        @showAuthenticationRequiredItems()
        #if @model.get('activeServer')?.get('type') is 'FieldDB'
        activeServerType = @getActiveServerType()
        if activeServerType is 'FieldDB'
          @showFieldDBItems()
          @hideOLDItems()
        else if activeServerType is 'OLD'
          @showOLDItems()
          @hideFieldDBItems()
        else
          @hideFieldDBItems()
          @hideOLDItems()
      else
        @hideAuthenticationRequiredItems()

    showFieldDBItems: ->
      @$('li.fielddb')
        .show()
        .find('a').removeClass 'disabled'

    hideFieldDBItems: ->
      @$('li.fielddb')
        .hide()
        .find('a').addClass 'disabled'

    showOLDItems: ->
      @$('li.old')
        .show()
        .find('a').removeClass 'disabled'

    hideOLDItems: ->
      @$('li.old')
        .hide()
        .find('a').addClass 'disabled'

    hideAuthenticationRequiredItems: ->
      @$('li.requires-authentication')
        .hide()
        .find('a').addClass 'disabled'

    showAuthenticationRequiredItems: ->
      @$('li.requires-authentication').not('.fielddb, .old')
        .show()
        .find('a').removeClass 'disabled'

    render: ->
      @$el
        .css(@constructor.jQueryUIColors().def) # match jQueryUI colors
        .html @template(@model.attributes)
      @setActivityAndVisibility()

      # NOTE @jrwdunham @cesine: I moved to superclick because touchscreen devices
      # don't support hover events, but apparently superfish does support touchscreen
      # devices (see http://users.tpg.com.au/j_birch/plugins/superfish/) so maybe we
      # should switch back.
      #@superfishify() # Superfish transmogrifies menu
      @superclickify() # Superclick transmogrifies menu

      @helpButtonState()
      @refreshLoginButton()
      @displayActiveCorpusName()
      @refreshLoggedInUser()
      @keyboardShortcuts()

    # Superfish jQuery plugin turns mainmenu <ul> into a menubar
    superfishify: ->
      @$('.sf-menu').supersubs(minWidth: 12, maxWidth: 27, extraWidth: 2)
        .superfish(autoArrows: false)
        .superfishJQueryUIMatch(@constructor.jQueryUIColors())

    # Superclick jQuery plugin turns mainmenu <ul> into a menubar
    superclickify: ->
      @$('.sf-menu')
        .supersubs
          minWidth: 12
          maxWidth: 27
          extraWidth: 2
        .superclick autoArrows: false
      @matchMenuToJQueryUITheme()

    closeSuperclick: ->
      @$('.sf-menu').superclick 'reset'

    # Configure keyboard shortcuts
    # 1. Bind shortcut keystrokes to the appropriate events.
    # 2. Modify the menu items so that shortcut abbreviations are displayed.
    keyboardShortcuts: ->
      try
        activeServerType = @getActiveServerType().toLowerCase()
      catch
        activeServerType = 'old'
      $(document).off 'keydown'
      for keyboardShortcut in keyboardShortcuts
        shortcut = keyboardShortcut.shortcut
        event = @getShortcutEvent keyboardShortcut, activeServerType
        $element = @$ "[data-event='#{event}']"
        if $element.hasClass 'disabled'
          @bindShortcutToEventTrigger shortcut, event, 'error'
        else
          @bindShortcutToEventTrigger shortcut, event
          shortcutAbbreviation = @getShortcutAbbreviation(shortcut)
          $element.append $('<span>').addClass('float-right').html(
            @getShortcutInFixedWithSpans(shortcutAbbreviation))

    getShortcutEvent: (keyboardShortcut, activeServerType) ->
      if 'event' of keyboardShortcut
        keyboardShortcut.event
      else
        keyboardShortcut[activeServerType].event

    getShortcutInFixedWithSpans: (shortcut) ->
      [initial..., last] = shortcut
      "#{initial.join('')}<span class='fixed-width'>#{last}</span>"

    # Bind keyboard shortcut to triggering of event.
    # If `type` is not `'normal'`, then an Error Notification will be triggered.
    bindShortcutToEventTrigger: (shortcutString, eventName, type='normal') ->
      # Map for 'ctrl+A' would be {ctrlKey: true, shortcutKey: 65}
      map = @getShortcutMap shortcutString

      # Bind the keydown event to the function
      $(document).keydown (event) =>
        if event.ctrlKey is map.ctrlKey and
        event.altKey is map.altKey and
        event.shiftKey is map.shiftKey and
        event.which is map.shortcutKey
          if type is 'normal'
            event.preventDefault()
            event.stopPropagation()
            @trigger eventName
          else
            Backbone.trigger 'disabledKeyboardShortcut', shortcutString

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
          when '?' then 191
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

    helpButtonState: ->
      @$('a.dative-help')
        .button()
        .css 'border-color', @constructor.jQueryUIColors().defBa
        .tooltip()

    # Initialize login/logout icon/button
    refreshLoginButton: ->
      if @model.get 'loggedIn'
        @$('a.dative-authenticated')
          .attr 'title', 'logout'
          .find('i').removeClass('fa-lock').addClass('fa-unlock-alt').end()
          .button()
          .css 'border-color', @constructor.jQueryUIColors().defBa
          .tooltip()
      else
        @$('a.dative-authenticated')
          .attr 'title', 'login'
          .find('i').removeClass('fa-unlock-alt').addClass('fa-lock').end()
          .button()
          .css 'border-color', @constructor.jQueryUIColors().defBa
          .tooltip()

    # Display the name of the active corpus at the top center of the menu bar.
    # If there is no active corpus, display the name of the active server.
    displayActiveCorpusName: ->
      activeFieldDBCorpusTitle = globals
        .applicationSettings?.get? 'activeFieldDBCorpusTitle'
      activeServerName = globals
        .applicationSettings?.get?('activeServer')?.get? 'name'
      activeServerType = globals
        .applicationSettings?.get?('activeServer')?.get? 'type'
      loggedIn = globals
        .applicationSettings?.get? 'loggedIn'
      text = null
      if activeFieldDBCorpusTitle
        text = activeFieldDBCorpusTitle
        title = "You are logged in to “#{activeServerName}” and are using the
          corpus “#{activeFieldDBCorpusTitle}”"
      else if activeServerName
        text = activeServerName
        if loggedIn
          if activeServerType is 'OLD'
            title = "You are logged in to the OLD server “#{activeServerName}”"
          else
            title = "You are logged in to the FieldDB server
              “#{activeServerName}” but have not yet activated a corpus"
        else
          title = "The active server is “#{activeServerName}”"
      else
        text = ''
        title = ''
      if text?
        @$('.active-corpus-name')
          .text text
          .attr 'title', title
          .tooltip()

    # Reset the tooltip title of the logged-in user's name in the top right.
    refreshLoggedInUser: ->
      if @model.get 'loggedIn'
        username = @model.get 'username'
        activeServerName = @model.get('activeServer')?.get 'name'
        activeServerType = @model.get('activeServer')?.get 'type'
        activeFieldDBCorpusTitle = @model.get 'activeFieldDBCorpusTitle'
        title = ["You are logged in to the server “#{activeServerName}”",
          "as “#{username}”"].join ' '
        if activeServerType is 'FieldDB' and activeFieldDBCorpusTitle
          title = ["#{title} and are using the corpus",
            "“#{activeFieldDBCorpusTitle}”"].join ' '
        @$('.logged-in-username')
          .text username
          .attr 'title', title
          .tooltip()

    # Tell the login dialog box to toggle itself.
    toggleLoginDialog: ->
      Backbone.trigger 'loginDialog:toggle'

    # Tell the help dialog box to toggle itself.
    toggleHelpDialog: ->
      Backbone.trigger 'helpDialog:toggle'

    # This replaces the functionality that used to be housed in the jQuery
    # extension `superclick-jqueryui-match` (and `superfish-jqueryui-match`).
    # Also see the mouse enter/leave/down/up event binddings in `@events`
    matchMenuToJQueryUITheme: ->

      selector = [
        'ul.sf-menu'
        'ul.sf-menu > li'
        'ul.sf-menu > li > a'
        'ul.sf-menu > li > ul'
        'ul.sf-menu > li > ul > li'
        'ul.sf-menu > li > ul > li a'
      ].join ', '
      @$(selector).css @constructor.jQueryUIColors().def

      selector = [
        'ul.sf-menu > li > ul > li:last-child',
        'ul.sf-menu > li > ul > li:last-child a'
      ].join ', '
      @$(selector).addClass 'ui-corner-bottom sf-option-bottom'

    mouseEnteredMenuItem: (event) ->
      $(event.currentTarget).css @constructor.jQueryUIColors().hov

    mouseLeftMenuItem: (event) ->
      $(event.currentTarget).css @constructor.jQueryUIColors().def

    mouseDownMenuItem: (event) ->
      $(event.currentTarget).css @constructor.jQueryUIColors().act

    mouseUpMenuItem: (event) ->
      $(event.currentTarget).css @constructor.jQueryUIColors().def

