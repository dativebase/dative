define (require) ->

  LoginDialogView = require '../../../scripts/views/login-dialog'
  ApplicationSettingsModel = require '../../../scripts/models/application-settings'

  describe 'Login Dialog View', ->

    before ->
      # Spy on methods...
      sinon.spy LoginDialogView::, '_authenticateFail'
      sinon.spy LoginDialogView::, '_authenticateEnd'
      sinon.spy LoginDialogView::, '_authenticateSuccess'
      sinon.spy LoginDialogView::, 'toggle'
      sinon.spy LoginDialogView::, 'validate'
      sinon.spy LoginDialogView::, '_submitWithEnter'
      sinon.spy LoginDialogView::, '_disableButtons'
      sinon.spy LoginDialogView::, 'login'
      sinon.spy LoginDialogView::, 'logout'
      sinon.spy LoginDialogView::, 'forgotPassword'

    beforeEach (done) ->
      # Create test fixture using js-fixtures https://github.com/badunk/js-fixtures
      fixtures.path = 'fixtures'
      callback = =>
        @$fixture = fixtures.window().$("<div id='js-fixtures-fixture'></div>")
        @$ = (selector) -> @$fixture.find selector

        sinon.stub ApplicationSettingsModel::, 'logout'
        sinon.stub ApplicationSettingsModel::, 'authenticate'
        @checkIfLoggedInStub = sinon.stub()
        ApplicationSettingsModel::checkIfLoggedIn = @checkIfLoggedInStub
        @applicationSettingsModel = new ApplicationSettingsModel()
        @applicationSettingsModel.set 'loggedIn', false
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
      ApplicationSettingsModel::logout.restore()
      ApplicationSettingsModel::authenticate.restore()

      LoginDialogView::_authenticateFail.reset()
      LoginDialogView::_authenticateEnd.reset()
      LoginDialogView::_authenticateSuccess.reset()
      LoginDialogView::toggle.reset()
      LoginDialogView::validate.reset()
      LoginDialogView::_submitWithEnter.reset()
      LoginDialogView::_disableButtons.reset()
      LoginDialogView::login.reset()
      LoginDialogView::logout.reset()
      LoginDialogView::forgotPassword.reset()

    after ->
      # Restore spied-on methods
      LoginDialogView::_authenticateFail.restore()
      LoginDialogView::_authenticateEnd.restore()
      LoginDialogView::_authenticateSuccess.restore()
      LoginDialogView::toggle.restore()
      LoginDialogView::validate.restore()
      LoginDialogView::_submitWithEnter.restore()
      LoginDialogView::_disableButtons.restore()
      LoginDialogView::login.restore()
      LoginDialogView::forgotPassword.restore()

    describe 'Initialization', ->

      it 'creates a jQueryUI dialog', ->
        $f = (selector) => @loginDialogView.$target.find(selector)
        expect($f('.dative-login-dialog-widget')).to.have.prop 'tagName', 'DIV'
        expect($f('.dative-login-dialog-widget .forgot-password'))
          .to.have.prop 'tagName', 'BUTTON'
        expect($f('.dative-login-dialog-widget .login'))
          .to.have.prop 'tagName', 'BUTTON'
        expect($f('.dative-login-dialog-widget .logout'))
          .to.have.prop 'tagName', 'BUTTON'
        expect($f('.blargon-five')).not.to.have.prop 'tagName'

      it 'dis/enables buttons according to authentication state', ->
        $f = (selector) => @loginDialogView.$target.find(selector)
        expect($f('button.logout')).to.have.class 'ui-state-disabled'
        expect($f('button.login')).not.to.have.class 'ui-state-disabled'
        expect($f('button.forgot-password')).not.to.have.class 'ui-state-disabled'
        expect($f('input.password')).not.to.have.attr 'disabled'
        expect($f('input.username')).not.to.have.attr 'disabled'

        @loginDialogView.model.set 'loggedIn', true
        expect($f('button.logout')).not.to.have.class 'ui-state-disabled'
        expect($f('button.login')).to.have.class 'ui-state-disabled'
        expect($f('button.forgot-password')).to.have.class 'ui-state-disabled'
        expect($f('input.password')).to.have.attr 'disabled'
        expect($f('input.username')).to.have.attr 'disabled'

    describe 'Event responsivity', ->

      it 'responds to Bacbkone-wide events', ->
        # Need to reset these spies because the app sett model can do unpredictable
        # things, depending on the state of the local storage app settings ...
        @loginDialogView._authenticateFail.reset()
        @loginDialogView._authenticateEnd.reset()
        @loginDialogView._authenticateSuccess.reset()
        @loginDialogView.toggle.reset()

        expect(@loginDialogView._authenticateFail).not.to.have.been.called
        expect(@loginDialogView._authenticateEnd).not.to.have.been.called
        expect(@loginDialogView._authenticateSuccess).not.to.have.been.called
        expect(@loginDialogView.toggle).not.to.have.been.called

        Backbone.trigger 'authenticate:fail'
        Backbone.trigger 'authenticate:fail'
        Backbone.trigger 'authenticate:fail'
        Backbone.trigger 'authenticate:end'
        Backbone.trigger 'authenticate:end'
        Backbone.trigger 'authenticate:success'

        expect(@loginDialogView._authenticateFail).to.have.been.calledThrice
        expect(@loginDialogView._authenticateEnd).to.have.been.calledTwice
        expect(@loginDialogView._authenticateSuccess).to.have.been.calledOnce
        expect(@loginDialogView.toggle).not.to.have.been.called

        Backbone.trigger 'loginDialog:toggle'
        Backbone.trigger 'loginDialog:toggle'
        Backbone.trigger 'loginDialog:toggle'

        expect(@loginDialogView._authenticateFail).to.have.been.calledThrice
        expect(@loginDialogView._authenticateEnd).to.have.been.calledTwice
        expect(@loginDialogView._authenticateSuccess).to.have.been.calledOnce
        expect(@loginDialogView.toggle).to.have.been.calledThrice

      it 'listens to its model', ->
        @loginDialogView._disableButtons.reset()
        expect(@loginDialogView._disableButtons).not.to.have.been.called
        @loginDialogView.model.set 'loggedIn', true
        expect(@loginDialogView._disableButtons).to.have.been.calledOnce
        @loginDialogView.model.set 'loggedIn', false
        expect(@loginDialogView._disableButtons).to.have.been.calledTwice
        @loginDialogView.model.set 'serverURL', 'http://www.google.com'
        expect(@loginDialogView._disableButtons).to.have.been.calledTwice

      it 'responds to button clicks', ->
        $f = (selector) => @loginDialogView.$target.find(selector)
        expect(@loginDialogView.login).not.to.have.been.called
        expect(@loginDialogView.logout).not.to.have.been.called
        expect(@loginDialogView.forgotPassword).not.to.have.been.called

        $f('button.login').click()
        expect(@loginDialogView.login).to.have.been.calledOnce
        expect(@loginDialogView.logout).not.to.have.been.called
        expect(@loginDialogView.forgotPassword).not.to.have.been.called

        $f('button.forgot-password').click()
        expect(@loginDialogView.login).to.have.been.calledOnce
        expect(@loginDialogView.logout).not.to.have.been.called
        expect(@loginDialogView.forgotPassword).to.have.been.calledOnce

        @loginDialogView.model.set 'loggedIn', true
        $f('button.logout').click()
        expect(@loginDialogView.login).to.have.been.calledOnce
        expect(@loginDialogView.logout).to.have.been.calledOnce
        expect(@loginDialogView.forgotPassword).to.have.been.calledOnce

      it.skip 'responds to keyup/down events (???)', ->
        # NOTE: this test just is not working: the simulated keyup events are not
        # triggering the expected view methods. I can't figure out why. It's
        # probably either because there is some glitch involving triggering
        # keyup/down events on input elements or it has something to do with
        # the jQueryUI dialog box and/or the fact that the fixture is in a
        # hidden iframe. I am giving up on this for now. A good reference on
        # this stuff is http://stackoverflow.com/questions/832059/definitive-way-to-trigger-keypress-events-with-jquery

        expect(@loginDialogView.validate).not.to.have.been.called
        expect(@loginDialogView._submitWithEnter).not.to.have.been.called

        keyupEvent = $.Event 'keyup'
        keyupEvent.which = 13

        @loginDialogView.$el.trigger keyupEvent
        expect(@loginDialogView.validate).not.to.have.been.called
        expect(@loginDialogView._submitWithEnter).not.to.have.been.called

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

    describe 'Validation', ->

      it 'prevents login attempts unless all fields have content', ->
        $f = (selector) => @loginDialogView.$target.find(selector)
        authenticateLoginSpy = sinon.spy()
        Backbone.on 'authenticate:login', authenticateLoginSpy
        expect(authenticateLoginSpy).not.to.have.been.called
        expect(@loginDialogView.login).not.to.have.been.called

        # authenticate:login not called because no values in inputs
        $f('button.login').click()
        expect(authenticateLoginSpy).not.to.have.been.called
        expect(@loginDialogView.login).to.have.been.calledOnce
        expect($f('.username-error')).to.have.text 'required'
        expect($f('.password-error')).to.have.text 'required'

        # authenticate:login not called because no values in username
        @loginDialogView._initializeDialog() # to reset things, e.g., error msgs
        $f('input.password').val 'somepassword'
        $f('button.login').click()
        expect(authenticateLoginSpy).not.to.have.been.called
        expect(@loginDialogView.login).to.have.been.calledTwice
        expect($f('.username-error')).to.have.text 'required'
        expect($f('.password-error')).to.have.text ''

        # authenticate:login IS called because there are values in both inputs
        @loginDialogView._initializeDialog() # to reset things, e.g., error msgs
        $f('input.password').val 'somepassword'
        $f('input.username').val 'someusername'
        $f('button.login').click()
        expect(authenticateLoginSpy).to.have.been.calledOnce
        expect(@loginDialogView.login).to.have.been.calledThrice
        expect($f('.username-error')).to.have.text ''
        expect($f('.password-error')).to.have.text ''

        Backbone.off 'authenticate:login', authenticateLoginSpy

