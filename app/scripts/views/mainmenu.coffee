define [
  'jquery'
  'backbone'
  './base'
  './../models/keyboard'
  './../utils/globals'
  './../utils/keyboard-shortcuts'
  './../templates/mainmenu'
  'superclick'
  'supersubs'
], ($, Backbone, BaseView, KeyboardModel, globals,
  keyboardShortcuts, mainmenuTemplate) ->

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
      @listenTo Backbone, 'keyboardInUse', @setStateHasActiveKeyboard

      # The currently active keyboard is the one that has been activated by the
      # user having focused a specific field which has a keyboard associated
      # with it.
      @activeKeyboard = null
      @activeKeyboardTarget = null

      # This will set our state to advertising the system-wide keyboard, if
      # there is one.
      @setStateHasActiveKeyboard()

    # A field has just gained focus and has signalled to the main menu that it
    # has an active keyboard. We therefore update how our keyboard button looks.
    setStateHasActiveKeyboard: (keyboardModel, $target) ->
      if keyboardModel
        @activeKeyboard = keyboardModel
        @activeKeyboardTarget = $target
        @$('.active-keyboard').addClass 'ui-state-highlight'
          .css 'border-color', @constructor.jQueryUIColors().actBo
          .tooltip(content:
            "view the active keyboard “#{keyboardModel.name}”")
      else
        @activeKeyboard = @getSystemWideKeyboard globals
        if @activeKeyboard
          @$('.active-keyboard').addClass 'ui-state-highlight'
            .css 'border-color', @constructor.jQueryUIColors().actBo
            .tooltip(content:
              "view the system-wide keyboard “#{@activeKeyboard.name}”")
        else
          @setStateHasNoActiveKeyboard()

    # A field with a keyboard has just lost focus and has signalled this fact
    # to the main menu. We therefore reset our keyboard button to its default
    # state. Note: we put a delay on this action so that clicking on the
    # keyboard button when there IS an active keyboard can have the correct
    # behaviour, i.e., displaying that active keyboard.
    setStateHasNoActiveKeyboard: ->
      cb = =>
        @activeKeyboard = null
        @activeKeyboardTarget = null
        @$('.active-keyboard').removeClass 'ui-state-highlight'
          .css 'border-color', @constructor.jQueryUIColors().defBa
          .tooltip content: 'browse keyboards in a dialog window'
      setTimeout cb, 100

    # Our small keyboard icon button has just been clicked. If we have an
    # active keyboard, show it; otherwise, render the keyboards browse
    # interface in a dialog window.
    showActiveKeyboard: (event) ->
      if globals.unicodeCharMap
        if @activeKeyboard
          keyboardModel = new KeyboardModel @activeKeyboard
          Backbone.trigger 'showEventBasedKeyboardInDialog', keyboardModel
          if @activeKeyboardTarget then @activeKeyboardTarget.focus()
        else
          @activeKeyboard = @getSystemWideKeyboard globals
          if @activeKeyboard
            keyboardModel = new KeyboardModel @activeKeyboard
            Backbone.trigger 'showEventBasedKeyboardInDialog', keyboardModel
          else
            @trigger 'meta:request:keyboardsBrowse'
      else
        @fetchUnicodeData(=> @showActiveKeyboard())

    activeFieldDBCorpusChanged: ->
      @refreshLoggedInUser()
      @displayActiveCorpusName()

    # When an element with a `data-event` attribute is clicked, the value of
    # that attribute is the Backbone event that is triggered. This makes the
    # menu buttons work.
    triggerMenuAction: (event) ->
      @$('.sf-menu').superclick 'reset'
      event.stopPropagation()
      $target = $ event.target
      # Menu items with a data-meta attribute can be clicked while holding down
      # the meta key in order to open in a dialog window.
      if $target.attr('data-meta') and event.metaKey
        @trigger "meta:#{$target.attr('data-event')}"
      else
        @trigger $target.attr('data-event')

    events:

      'click [data-event]': 'triggerMenuAction'
      'click a.dative-authenticated': 'toggleLoginDialog'
      'click a.dative-help': 'toggleHelpDialog'
      'click a.active-keyboard': 'showActiveKeyboard'

      'mouseenter ul.sf-menu > li > ul > li': 'mouseEnteredMenuItem'
      'mouseenter ul.sf-menu > li > ul > li > a': 'mouseEnteredMenuItem'
      'mouseenter ul.sf-menu > li > ul > li > ul > li': 'mouseEnteredMenuItem'
      'mouseenter ul.sf-menu > li > ul > li > ul > li > a': 'mouseEnteredMenuItem'

      'mouseleave ul.sf-menu > li > ul > li': 'mouseLeftMenuItem'
      'mouseleave ul.sf-menu > li > ul > li > a': 'mouseLeftMenuItem'
      'mouseleave ul.sf-menu > li > ul > li > ul > li': 'mouseLeftMenuItem'
      'mouseleave ul.sf-menu > li > ul > li > ul > li > a': 'mouseLeftMenuItem'

      'mousedown ul.sf-menu > li': 'mouseDownMenuItem'
      'mousedown ul.sf-menu > li > a': 'mouseDownMenuItem'
      'mousedown ul.sf-menu > li > ul > li': 'mouseDownMenuItem'
      'mousedown ul.sf-menu > li > ul > li > a': 'mouseDownMenuItem'
      'mousedown ul.sf-menu > li > ul > li > ul > li': 'mouseDownMenuItem'
      'mousedown ul.sf-menu > li > ul > li > ul > li > a': 'mouseDownMenuItem'

      'mouseup ul.sf-menu > li': 'mouseUpMenuItem'
      'mouseup ul.sf-menu > li > a': 'mouseUpMenuItem'
      'mouseup ul.sf-menu > li > ul > li': 'mouseUpMenuItem'
      'mouseup ul.sf-menu > li > ul > li > a': 'mouseUpMenuItem'
      'mouseup ul.sf-menu > li > ul > li > ul > li': 'mouseUpMenuItem'
      'mouseup ul.sf-menu > li > ul > li > ul > li > a': 'mouseUpMenuItem'

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
      @copyHideableMenuItemsToOverflow()
      @setActivityAndVisibility()

      # NOTE @jrwdunham @cesine: I moved to superclick because touchscreen
      # devices don't support hover events, but apparently superfish does
      # support touchscreen devices (see
      # http://users.tpg.com.au/j_birch/plugins/superfish/) so maybe we should
      # switch back.
      #@superfishify() # Superfish transmogrifies menu
      @superclickify() # Superclick transmogrifies menu

      @helpButtonState()
      @keyboardButtonState()
      @refreshLoginButton()
      @displayActiveCorpusName()
      @refreshLoggedInUser()
      @keyboardShortcuts()
      @setStateHasActiveKeyboard()
      @adjustToWindowDimensions()

    adjustToWindowDimensions: ->
      @hideMenuItemsBasedOnWindowDimensions $(window).width()
      $(window).resize =>
        @hideMenuItemsBasedOnWindowDimensions $(window).width()

    # If the window gets too narrow, we hide the "hideable" menu items and
    # display the overflow double right angle menu item >> which contains
    # copies of those hideable menu items.
    hideMenuItemsBasedOnWindowDimensions: (windowWidth) ->
      if windowWidth < 1237
        if not @$('li.menu-overflow').is(':visible')
          @$('ul.sf-menu > li.hideable').hide()
          @$('li.menu-overflow').show()
      else
        if @$('li.menu-overflow').is ':visible'
          @$('ul.sf-menu > li.hideable').show()
          @$('li.menu-overflow').hide()
      if windowWidth < 520
        if @$('div.active-corpus-name').is ':visible'
          @$('div.active-corpus-name').hide()
      else
        if not @$('div.active-corpus-name').is(':visible')
          @$('div.active-corpus-name').show()

    # We copy the hideable menu items' HTML to the menu-overflow menu item.
    copyHideableMenuItemsToOverflow: ->
      @$('li.hideable').clone().appendTo 'li.menu-overflow > ul'

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
            if event.metaKey
              @trigger "meta:#{eventName}"
            else
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

    keyboardButtonState: ->
      @$('a.active-keyboard')
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
        'ul.sf-menu > li > ul > li > ul > li'
        'ul.sf-menu > li > ul > li > ul > li a'
      ].join ', '
      @$(selector).css @constructor.jQueryUIColors().def

      selector = [
        'ul.sf-menu > li > ul > li:last-child',
        'ul.sf-menu > li > ul > li:last-child a'
        'ul.sf-menu > li > ul > li > ul > li:last-child',
        'ul.sf-menu > li > ul > li > ul > li:last-child a'
      ].join ', '
      @$(selector).addClass 'ui-corner-bottom sf-option-bottom'

      selector = [
        'ul.sf-menu > li > ul > li > ul > li:first-child',
        'ul.sf-menu > li > ul > li > ul > li:first-child a'
      ].join ', '
      @$(selector).addClass 'ui-corner-tr sf-option-top'

    mouseEnteredMenuItem: (event) ->
      $(event.currentTarget).css @constructor.jQueryUIColors().hov

    mouseLeftMenuItem: (event) ->
      $(event.currentTarget).css @constructor.jQueryUIColors().def

    mouseDownMenuItem: (event) ->
      $(event.currentTarget).css @constructor.jQueryUIColors().act

    mouseUpMenuItem: (event) ->
      $(event.currentTarget).css @constructor.jQueryUIColors().def

