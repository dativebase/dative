define (require) ->

  ApplicationSettingsView = require '../../../scripts/views/application-settings'
  ApplicationSettingsModel = require '../../../scripts/models/application-settings'

  # Convenience function to simulate keyboard shortcut events.
  simulateShortcut = (shortcutString) =>
    shortcutMap = @mainMenuView.getShortcutMap shortcutString
    keydownEvent = $.Event 'keydown'
    keydownEvent.ctrlKey = shortcutMap.ctrlKey
    keydownEvent.altKey = shortcutMap.altKey
    keydownEvent.shiftKey = shortcutMap.shiftKey
    keydownEvent.which = shortcutMap.shortcutKey
    $(document).trigger keydownEvent

  describe 'Application Settings View', ->

    before ->

      # Spy on some of ApplicationSettingsView's methods
      sinon.spy ApplicationSettingsView::, 'edit'
      sinon.spy ApplicationSettingsView::, 'view'
      sinon.spy ApplicationSettingsView::, 'save'
      sinon.spy ApplicationSettingsView::, '_keyboardControl'

    beforeEach (done) ->

      # Create test fixture using js-fixtures https://github.com/badunk/js-fixtures
      fixtures.path = 'fixtures'
      callback = =>
        @$fixture = fixtures.window().$("<div id='js-fixtures-fixture'></div>")
        @$ = (selector) -> @$fixture.find selector

        # New appSetView for each test
        # We stub the checkIfLoggedIn method of the app settings model just so that
        # the console isn't filled with failed CORS requests.
        @checkIfLoggedInStub = sinon.stub()
        ApplicationSettingsModel::checkIfLoggedIn = @checkIfLoggedInStub
        @applicationSettingsModel = new ApplicationSettingsModel()
        @appSetView = new ApplicationSettingsView
          el: @$fixture
          model: @applicationSettingsModel
        @appSetView.render()
        done()

      fixtures.load('fixture.html', callback)

    afterEach ->

      fixtures.cleanUp()

      @checkIfLoggedInStub.reset()

      @appSetView.close()
      @appSetView.remove()

      # Reset spies
      ApplicationSettingsView::.edit.reset()
      ApplicationSettingsView::.view.reset()
      ApplicationSettingsView::.save.reset()
      ApplicationSettingsView::._keyboardControl.reset()

    after ->

      # Restore spied-on methods
      ApplicationSettingsView::.edit.restore()
      ApplicationSettingsView::.view.restore()
      ApplicationSettingsView::.save.restore()
      ApplicationSettingsView::._keyboardControl.restore()
      ApplicationSettingsModel::._checkIfLoggedIn.restore()

    describe 'Event responsivity', ->

      it 'listens to events emitted by its subviews', ->
        expect(@appSetView.edit).not.to.have.been.called
        expect(@appSetView.view).to.have.been.calledOnce # `render` in `beforeEach` calls `view`
        expect(@appSetView.save).not.to.have.been.called

        Backbone.trigger 'applicationSettings:edit'
        Backbone.trigger 'applicationSettings:view'
        Backbone.trigger 'applicationSettings:view'
        Backbone.trigger 'applicationSettings:save'
        Backbone.trigger 'applicationSettings:save'
        Backbone.trigger 'applicationSettings:save'

        expect(@appSetView.edit).to.have.been.calledOnce
        expect(@appSetView.save).to.have.been.calledThrice
        # `save` only calls `view` if the model has changed
        expect(@appSetView.view).to.have.been.calledThrice

      it 'listens to its model', ->
        expect(@appSetView.edit).not.to.have.been.called
        expect(@appSetView.view).to.have.been.calledOnce
        expect(@appSetView.save).not.to.have.been.called
        expect(@appSetView._keyboardControl)
          .not.to.have.been.called
        @appSetView.model.set 'serverURL', 'www.google.ca'
        expect(@appSetView.edit).not.to.have.been.called
        expect(@appSetView.view).to.have.been.calledTwice
        expect(@appSetView.save).not.to.have.been.called
        expect(@appSetView._keyboardControl)
          .not.to.have.been.called

      it 'listens to DOM events', ->
        expect(@appSetView.edit).not.to.have.been.called
        expect(@appSetView.view).to.have.been.calledOnce
        expect(@appSetView.save).not.to.have.been.called
        expect(@appSetView._keyboardControl)
          .not.to.have.been.called

        @appSetView.$('.edit').click()
        expect(@appSetView.edit).to.have.been.calledOnce
        expect(@appSetView.view).to.have.been.calledOnce
        expect(@appSetView.save).not.to.have.been.called
        expect(@appSetView._keyboardControl)
          .not.to.have.been.called

        @appSetView.$('.view').click()
        expect(@appSetView.edit).to.have.been.calledOnce
        expect(@appSetView.view).to.have.been.calledTwice
        expect(@appSetView.save).not.to.have.been.called
        expect(@appSetView._keyboardControl)
          .not.to.have.been.called

        @appSetView.$('.edit').first().click()
        expect(@appSetView.edit).to.have.been.calledTwice
        expect(@appSetView.view).to.have.been.calledTwice
        expect(@appSetView.save).not.to.have.been.called
        expect(@appSetView._keyboardControl)
          .not.to.have.been.called

        @appSetView.$('.save').first().click()
        expect(@appSetView.edit).to.have.been.calledTwice
        expect(@appSetView.view).to.have.been.calledTwice
        expect(@appSetView.save).to.have.been.calledOnce
        expect(@appSetView._keyboardControl)
          .not.to.have.been.called

        @appSetView.$('.dative-display').first().click()
        expect(@appSetView.edit).to.have.been.calledThrice
        expect(@appSetView.view).to.have.been.calledTwice
        expect(@appSetView.save).to.have.been.calledOnce
        expect(@appSetView._keyboardControl)
          .not.to.have.been.called

      it 'listens to keydown events', ->

        editCountInit = @appSetView.edit.callCount
        viewCountInit = @appSetView.view.callCount
        saveCountInit = @appSetView.save.callCount

        # Pressing "A" does nothing
        expect(@appSetView._keyboardControl).not.to.have.been.called
        keydownEvent = fixtures.window().$.Event 'keydown'
        keydownEvent.which = 95 # *not* a shortcut key
        @appSetView.$('.dative-display').eq(0).trigger keydownEvent
        expect(@appSetView._keyboardControl).to.have.been.calledOnce
        expect(@appSetView.edit.callCount).to.equal editCountInit
        expect(@appSetView.view.callCount).to.equal viewCountInit
        expect(@appSetView.save.callCount).to.equal saveCountInit

        # Pressing <Esc> in view mode does nothing
        keydownEvent.which = 27
        @appSetView.$('.dative-display').eq(0).trigger keydownEvent
        expect(@appSetView._keyboardControl).to.have.been.calledTwice
        expect(@appSetView.edit.callCount).to.equal editCountInit
        expect(@appSetView.view.callCount).to.equal viewCountInit
        expect(@appSetView.save.callCount).to.equal saveCountInit

        # Pressing <Esc> in edit mode returns us to view mode
        @appSetView.edit()
        @appSetView.$('.dative-input').eq(0).trigger keydownEvent
        expect(@appSetView._keyboardControl).to.have.been.calledThrice
        expect(@appSetView.edit.callCount).to.equal editCountInit + 1
        expect(@appSetView.view.callCount).to.equal viewCountInit + 1
        expect(@appSetView.save.callCount).to.equal saveCountInit
        editCountInit++
        viewCountInit++

        # Pressing <Enter> in view mode when the view's root node is focused
        # does nothing
        keydownEvent.which = 13
        @appSetView.$el.trigger keydownEvent
        expect(@appSetView._keyboardControl).to.have.been.calledThrice
        expect(@appSetView.edit.callCount).to.equal editCountInit
        expect(@appSetView.view.callCount).to.equal viewCountInit
        expect(@appSetView.save.callCount).to.equal saveCountInit

        # Pressing <Enter> in view mode on a data display item brings us to
        # edit mode
        @appSetView.$('.dative-display').eq(0).trigger keydownEvent
        expect(@appSetView._keyboardControl.callCount).to.equal 4
        expect(@appSetView.edit.callCount).to.equal editCountInit + 1
        expect(@appSetView.view.callCount).to.equal viewCountInit
        expect(@appSetView.save.callCount).to.equal saveCountInit
        editCountInit++

        # Pressing <Enter> in edit mode on an input calls `save`, which calls
        # `view`
        @appSetView.$('.dative-input').eq(0).trigger keydownEvent
        expect(@appSetView._keyboardControl.callCount).to.equal 5
        expect(@appSetView.edit.callCount).to.equal editCountInit
        expect(@appSetView.view.callCount).to.equal viewCountInit
        expect(@appSetView.save.callCount).to.equal saveCountInit + 1

    describe 'Saves state', ->

      it 'saves form data to its model, triggering events in other views', ->

        editCountInit = @appSetView.edit.callCount
        viewCountInit = @appSetView.view.callCount
        saveCountInit = @appSetView.save.callCount

        expect(@appSetView.edit).not.to.have.been.called
        expect(@appSetView.view).to.have.been.calledOnce
        expect(@appSetView.save).not.to.have.been.called

        # Go to edit view, change the server url, and click 'Save'
        @appSetView.edit()
        @appSetView.$('[name="serverURL"]').val 'http://www.google.com/'
        @appSetView.$('.save').first().click()

        expect(@appSetView.edit).to.have.been.calledOnce
        expect(@appSetView.view).to.have.been.calledTwice
        expect(@appSetView.save).to.have.been.calledOnce
        expect(@appSetView.$('label[for="serverURL"]').next())
          .to.have.text 'http://www.google.com/'

