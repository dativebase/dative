define (require) ->

  MainMenuView = require '../../../scripts/views/mainmenu'
  ApplicationSettingsModel = require '../../../scripts/models/application-settings'

  describe 'Main Menu View', ->

    before ->
      # Create test fixture.
      @$fixture = $("<div id='main-menu-view-fixture'></div>")

    beforeEach ->
      # Empty out and rebind the fixture for each run.
      @$fixture.empty().appendTo $('#fixtures')

      # New default model and view for each test
      @applicationSettings = new ApplicationSettingsModel()
      #@applicationSettings.fetch()
      @mainMenuView = new MainMenuView(
        model: @applicationSettings
        el: @$fixture
      )

    afterEach ->
      @mainMenuView.remove()
      @applicationSettings.destroy()

    after ->
      $('#fixtures').empty()

    it 'parses shortcut strings correctly', ->
      map = @mainMenuView.getShortcutMap 'ctrl+A'
      expect(map).to.have.property 'ctrlKey', true
      expect(map).to.have.property 'altKey', false
      expect(map).to.have.property 'shiftKey', false
      expect(map).to.have.property 'shortcutKey', 65

      map = @mainMenuView.getShortcutMap 'ctrl+a'
      expect(map).to.have.property 'ctrlKey', true
      expect(map).to.have.property 'altKey', false
      expect(map).to.have.property 'shiftKey', false
      expect(map).to.have.property 'shortcutKey', 65

      map = @mainMenuView.getShortcutMap 'alt+ctrl+z'
      expect(map).to.have.property 'ctrlKey', true
      expect(map).to.have.property 'altKey', true
      expect(map).to.have.property 'shiftKey', false
      expect(map).to.have.property 'shortcutKey', 90

      map = @mainMenuView.getShortcutMap 'z'
      expect(map).to.have.property 'ctrlKey', false
      expect(map).to.have.property 'altKey', false
      expect(map).to.have.property 'shiftKey', false
      expect(map).to.have.property 'shortcutKey', 90

      map = @mainMenuView.getShortcutMap 'shift+ctrl+alt+rArrow'
      expect(map).to.have.property 'ctrlKey', true
      expect(map).to.have.property 'altKey', true
      expect(map).to.have.property 'shiftKey', true
      expect(map).to.have.property 'shortcutKey', 39

    it 'generates shortcut abbreviations from shortcut strings', ->
      abbr = @mainMenuView.getShortcutAbbreviation 'shift+ctrl+alt+dArrow'
      expect(abbr).to.equal '\u2303\u2325\u21E7\u2193'

      abbr = @mainMenuView.getShortcutAbbreviation 'ctrl+a'
      expect(abbr).to.equal '\u2303A'

    it 'fires the correct event when a menu button is clicked', ->
      @mainMenuView.render()
      buttons = [] # array of 2-arrays: $-wrapped button and spy
      for button in @mainMenuView.$('[data-event]').get()
        button = $(button)
        spy = sinon.spy()
        dataEvent = button.attr 'data-event'
        @mainMenuView.on dataEvent, spy
        buttons.push [button, spy]

      # Click just the first button once.
      [$firstButton, firstSpy] = buttons[0]
      for [$button, spy] in buttons
        expect(spy).not.to.have.been.called
      $firstButton.click()
      expect(firstSpy).to.have.been.calledOnce
      for [$button, spy] in buttons[1..]
        expect(spy).not.to.have.been.called

      # Click all of the buttons twice.
      for [$button, spy] in buttons
        $button.click()
        $button.click()
      expect(firstSpy).to.have.been.calledThrice
      for [$button, spy] in buttons[1..]
        # Some menu buttons have the same data-event value so clicking one
        # twice will call the spy of the other another two times; hence some
        # spies will have been called four times.
        expect(spy.callCount).to.be.at.least 2
        expect(spy.callCount).to.be.at.most 4

    it 'fires the correct event when a keyboard shortcut is pressed', ->
      @mainMenuView.render()
      buttons = [] # array of 3-arrays: $-wrapped button, spy, and shortcut string
      for button in @mainMenuView.$('[data-shortcut]').get()
        button = $(button)
        spy = sinon.spy()
        dataEvent = button.attr 'data-event'
        dataShortcut = button.attr 'data-shortcut'
        @mainMenuView.on dataEvent, spy
        buttons.push [button, spy, dataShortcut]

      # Convenience function to simulate keyboard shortcut events.
      simulateShortcut = (shortcutString) =>
        shortcutMap = @mainMenuView.getShortcutMap shortcutString
        keydownEvent = $.Event 'keydown'
        keydownEvent.ctrlKey = shortcutMap.ctrlKey
        keydownEvent.altKey = shortcutMap.altKey
        keydownEvent.shiftKey = shortcutMap.shiftKey
        keydownEvent.which = shortcutMap.shortcutKey
        $(document).trigger keydownEvent

      # Execute just the first shortcut.
      [$firstButton, firstSpy, firstShortcut] = buttons[0]
      for [$button, spy] in buttons
        expect(spy).not.to.have.been.called
      simulateShortcut firstShortcut
      expect(firstSpy).to.have.been.calledOnce
      for [$button, spy] in buttons[1..]
        expect(spy).not.to.have.been.called

      # Execute all keyboard shortcuts twice.
      for [$button, spy, shortcutString] in buttons
        simulateShortcut shortcutString
        simulateShortcut shortcutString
      expect(firstSpy).to.have.been.calledThrice
      for [$button, spy] in buttons[1..]
        expect(spy).to.have.been.calledTwice

    it 'appends the correct keyboard shortcut to the menu button name', ->
      @mainMenuView.render()
      for button in @mainMenuView.$('[data-shortcut]').get()
        button = $(button)
        shortcutString = button.attr 'data-shortcut'
        abbr = @mainMenuView.getShortcutAbbreviation shortcutString
        expect(button.text()).to.contain abbr

    it 'indicates whether the user is logged in.', ->
      @mainMenuView.render()
      $iconSpan = @mainMenuView
        .$('a.dative-authenticated span.ui-button-icon-primary')
      if @applicationSettings.get 'loggedIn'
        expect($iconSpan.attr('class')).to.contain 'ui-icon-unlocked'
      else
        expect($iconSpan.attr('class')).to.contain 'ui-icon-locked'

      @applicationSettings.set 'loggedIn', true
      $iconSpan = @mainMenuView
        .$('a.dative-authenticated span.ui-button-icon-primary')
      expect($iconSpan.attr('class')).to.contain 'ui-icon-unlocked'

      @applicationSettings.set 'loggedIn', false
      $iconSpan = @mainMenuView
        .$('a.dative-authenticated span.ui-button-icon-primary')
      expect($iconSpan.attr('class')).to.contain 'ui-icon-locked'

    it 'fires Backbone-wide loginDialog:toggle event when the login icon is clicked.', ->
      # NOTE: It's necessary to set the spy on the prototype before the
      # main menu object has been created.
      # Cf. http://stackoverflow.com/questions/9113186/backbone-js-click-event-spy-is-not-getting-called-using-jasmine-js-and-sinon-js
      # For additional discussion, see pp. 117-119 of Backbone.js Testing.
      loginDialogToggleEventSpy = sinon.spy()
      toggleLoginDialogSpy = sinon.spy MainMenuView::, 'toggleLoginDialog'
      mainMenuView = new MainMenuView(
        model: @applicationSettings
        el: @$fixture
      )
      Backbone.once 'loginDialog:toggle', loginDialogToggleEventSpy
      mainMenuView.render()
      expect(loginDialogToggleEventSpy).not.to.have.been.called
      expect(toggleLoginDialogSpy).not.to.have.been.called
      $('a.dative-authenticated').first().click()
      expect(toggleLoginDialogSpy).to.have.been.calledOnce
      expect(loginDialogToggleEventSpy).to.have.been.calledOnce
      MainMenuView::.toggleLoginDialog.restore()

