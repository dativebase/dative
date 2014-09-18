define (require) ->

  LoginDialogView = require '../../../scripts/views/login-dialog'
  ApplicationSettingsModel = require '../../../scripts/models/application-settings'

  describe 'Login Dialog View', ->

    before ->
      # Spy on methods...
      sinon.spy LoginDialogView::, 'authenticateFail'
      sinon.spy LoginDialogView::, 'authenticateEnd'
      sinon.spy LoginDialogView::, 'authenticateSuccess'
      sinon.spy LoginDialogView::, 'toggle'
      sinon.spy LoginDialogView::, 'validate'
      sinon.spy LoginDialogView::, 'submitWithEnter'

    beforeEach (done) ->
      # Create test fixture using js-fixtures https://github.com/badunk/js-fixtures
      fixtures.path = 'fixtures'
      callback = =>
        @$fixture = fixtures.window().$("<div id='js-fixtures-fixture'></div>")
        @$ = (selector) -> @$fixture.find selector

        @checkIfLoggedInStub = sinon.stub()
        ApplicationSettingsModel::checkIfLoggedIn = @checkIfLoggedInStub
        @applicationSettingsModel = new ApplicationSettingsModel()
        @loginDialogView = new LoginDialogView
          el: @$fixture
          model: @applicationSettingsModel
        @loginDialogView.render()
        done()
      fixtures.load('fixture.html', callback)

    afterEach ->
      fixtures.cleanUp()
      @loginDialogView.close()
      @loginDialogView.remove()

      # Reset spies & stubs
      @checkIfLoggedInStub.reset()
      LoginDialogView::authenticateFail.reset()
      LoginDialogView::authenticateEnd.reset()
      LoginDialogView::authenticateSuccess.reset()
      LoginDialogView::toggle.reset()
      LoginDialogView::validate.reset()
      LoginDialogView::submitWithEnter.reset()

    after ->
      # Restore spied-on methods
      LoginDialogView::authenticateFail.restore()
      LoginDialogView::authenticateEnd.restore()
      LoginDialogView::authenticateSuccess.restore()
      LoginDialogView::toggle.restore()
      LoginDialogView::validate.restore()
      LoginDialogView::submitWithEnter.restore()

    describe 'Event responsivity', ->

      it 'responds to Bacbkone-wide events', ->
        # Need to reset these spies because the app sett model can do unpredictable
        # things, depending on the state of the local storage app settings ...
        @loginDialogView.authenticateFail.reset()
        @loginDialogView.authenticateEnd.reset()
        @loginDialogView.authenticateSuccess.reset()
        @loginDialogView.toggle.reset()

        expect(@loginDialogView.authenticateFail).not.to.have.been.called
        expect(@loginDialogView.authenticateEnd).not.to.have.been.called
        expect(@loginDialogView.authenticateSuccess).not.to.have.been.called
        expect(@loginDialogView.toggle).not.to.have.been.called

        Backbone.trigger 'authenticate:fail'
        Backbone.trigger 'authenticate:fail'
        Backbone.trigger 'authenticate:fail'
        Backbone.trigger 'authenticate:end'
        Backbone.trigger 'authenticate:end'
        Backbone.trigger 'authenticate:success'

        expect(@loginDialogView.authenticateFail).to.have.been.calledThrice
        expect(@loginDialogView.authenticateEnd).to.have.been.calledTwice
        expect(@loginDialogView.authenticateSuccess).to.have.been.calledOnce
        expect(@loginDialogView.toggle).not.to.have.been.called

        Backbone.trigger 'loginDialog:toggle'
        Backbone.trigger 'loginDialog:toggle'
        Backbone.trigger 'loginDialog:toggle'

        expect(@loginDialogView.authenticateFail).to.have.been.calledThrice
        expect(@loginDialogView.authenticateEnd).to.have.been.calledTwice
        expect(@loginDialogView.authenticateSuccess).to.have.been.calledOnce
        expect(@loginDialogView.toggle).to.have.been.calledThrice

      it.skip 'validates on input changes (keyup/down events)', ->
        # NOTE: this test just is not working: the simulated keyup events are not
        # triggering the expected view methods. I can't figure out why. It's
        # probably either because there is some glitch involving triggering
        # keyup/down events on input elements or it has something to do with
        # the jQueryUI dialog box and/or the fact that the fixture is in a
        # hidden iframe. I am giving up on this for now. A good reference on
        # this stuff is http://stackoverflow.com/questions/832059/definitive-way-to-trigger-keypress-events-with-jquery

        expect(@loginDialogView.validate).not.to.have.been.called
        expect(@loginDialogView.submitWithEnter).not.to.have.been.called

        keyupEvent = $.Event 'keyup'
        keyupEvent.which = 13

        @loginDialogView.$el.trigger keyupEvent
        expect(@loginDialogView.validate).not.to.have.been.called
        expect(@loginDialogView.submitWithEnter).not.to.have.been.called

        #@loginDialogView.dialogOpen() # even doing this doesn't help things ...
        @loginDialogView.$el.find('.dative-login-dialog-widget .username')
          .trigger keyupEvent

        # None of the following cause the `validate` method to be called, even 
        # though it should be called (and is when you manually explore the GUI...)
        @loginDialogView.$source.find('.password').trigger keyupEvent
        @loginDialogView.$source.find('.password').first().trigger keyupEvent
        @loginDialogView.$target.find('.password').first().focus().trigger keyupEvent
        @loginDialogView.$source.find('.password').first().focus()
        @loginDialogView.$source.find('.password').trigger keyupEvent

        # This will fail
        expect(@loginDialogView.validate).to.have.been.calledOnce
        console.log @loginDialogView.validate.callCount # returns 0, should return 1

      it 'recognizes keyboard controls'

      it 'listens to its model'

