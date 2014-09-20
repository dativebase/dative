define (require) ->

  AppView = require '../../../scripts/views/app'
  PagesView = require '../../../scripts/views/pages'
  FormAddView = require '../../../scripts/views/form-add'
  ApplicationSettingsModel = require '../../../scripts/models/application-settings'

  describe 'App View', ->

    before ->

      # Spy on some of AppView's methods
      sinon.spy AppView::, 'render'
      sinon.spy AppView::, 'showPagesView'
      sinon.spy AppView::, 'showFormAddView'
      sinon.spy AppView::, 'showFormsView'
      sinon.spy AppView::, 'toggleLoginDialog'
      sinon.spy AppView::, 'showApplicationSettingsView'

    beforeEach (done) ->

      # Create test fixture using js-fixtures https://github.com/badunk/js-fixtures
      fixtures.path = 'fixtures'
      callback = =>
        @$fixture = fixtures.window().$("<div id='js-fixtures-fixture'></div>")
        @document = fixtures.window().document
        @$ = (selector) -> @$fixture.find selector

        # New appView for each test
        # We stub the checkIfLoggedIn method of the app settings model just so that
        # the console isn't filled with failed CORS requests.
        @checkIfLoggedInStub = sinon.stub()
        ApplicationSettingsModel::checkIfLoggedIn = @checkIfLoggedInStub
        @applicationSettingsModel = new ApplicationSettingsModel()
        @appView = new AppView
          el: @$fixture
          applicationSettings: @applicationSettingsModel

        done()

      fixtures.load('fixture.html', callback)

      # Empty out and rebind the fixture for each run.
      #@$fixture.empty().appendTo $('#fixtures')

    afterEach ->

      fixtures.cleanUp()

      @checkIfLoggedInStub.reset()

      @appView.close()
      @appView.remove()

      AppView::render.reset()
      AppView::showPagesView.reset()
      AppView::showFormAddView.reset()
      AppView::showFormsView.reset()
      AppView::toggleLoginDialog.reset()
      AppView::showApplicationSettingsView.reset()

    after ->

      AppView::render.restore()
      AppView::showPagesView.restore()
      AppView::showFormAddView.restore()
      AppView::showFormsView.restore()
      AppView::toggleLoginDialog.restore()
      AppView::showApplicationSettingsView.restore()

    describe 'Initialization', ->

      it 'renders itself and its persistent sub-views on initialization', ->

        $mainmenu = @$ '#mainmenu'
        $progressWidgetContainer = @$ '#progress-widget-container'
        $notifierContainer = @$ '#notifier-container'
        $appView = @$ '#appview'
        $loginDialog = @$ 'div.dative-login-dialog'

        # Initialization calls render
        expect(@appView.render).to.have.been.calledOnce
        expect(@appView._renderedSubViews).to.have.length 4
        expect($mainmenu).to.have.prop 'tagName', 'DIV'
        expect(@$('#nonexistent-id').prop('tagName')).to.be.undefined

        # Test that the main menu, progress widget, container widget, and login
        # dialog are rendered as expected.
        $mainmenuFirstChild = $mainmenu.children().first()
        expect($mainmenuFirstChild).to.have.prop 'tagName', 'UL'
        expect($mainmenuFirstChild).to.have.class 'sf-menu'

        $progressFirstChild = $progressWidgetContainer.children().first()
        expect($progressFirstChild).to.have.prop 'tagName', 'DIV'
        expect($progressFirstChild).to.have.class 'progress-widget'

        expect($notifierContainer).to.have.html ''
        expect($appView).to.have.html ''

        $loginDialogFirstChild = $loginDialog.children().first()
        expect($loginDialogFirstChild).to.have.prop 'tagName', 'FORM'
        expect($loginDialogFirstChild).to.have.class 'loginLogin'

    describe 'Event responsivity', ->

      it 'listens to main menu events', ->
        expect(@appView.showPagesView).not.to.have.been.called
        expect(@appView.showFormAddView).not.to.have.been.called
        expect(@appView.showFormsView).not.to.have.been.called
        expect(@appView.toggleLoginDialog).not.to.have.been.called
        expect(@appView.showApplicationSettingsView).not.to.have.been.called

        @appView.mainMenuView.trigger 'request:openLoginDialogBox'
        @appView.mainMenuView.trigger 'request:pages'
        @appView.mainMenuView.trigger 'request:pages'
        @appView.mainMenuView.trigger 'request:formAdd'
        @appView.mainMenuView.trigger 'request:formAdd'
        @appView.mainMenuView.trigger 'request:formAdd'

        expect(@appView.showPagesView).to.have.been.calledTwice
        expect(@appView.showFormAddView).to.have.been.calledThrice
        expect(@appView.showFormsView).not.to.have.been.called
        expect(@appView.toggleLoginDialog).to.have.been.calledOnce
        expect(@appView.showApplicationSettingsView).not.to.have.been.called

    describe 'Subview management', ->

      it 'renders app views in response to main menu events', (done) ->
        @appView.mainMenuView.once('request:pages', =>
          expect(@appView.$('div.dative-page-header-title'))
            .to.have.text 'Pages'
          @appView.mainMenuView.trigger 'request:formAdd'
        )

        @appView.mainMenuView.once('request:formAdd', =>
          expect(@appView.$('div.dative-page-header-title'))
            .to.have.text 'Add a Form'
          done()
        )

        @appView.mainMenuView.trigger 'request:pages'

      it 'correctly renders/closes visible subviews', (done) ->

        @appView.mainMenuView.once 'request:pages', =>
          expect(@appView.$('.dative-page-header-title')).to.have.text 'Pages'
          expect(@appView._visibleView).to.exist.and
            .to.be.an.instanceof PagesView
          expect(@appView._renderedSubViews).to.have.length 5
          @appView.mainMenuView.trigger 'request:formAdd'

        @appView.mainMenuView.once 'request:formAdd', =>
          expect(@appView.$('.dative-page-header-title')).to.have.text 'Add a Form'
          expect(@appView._visibleView).to.exist.and
            .to.be.an.instanceof FormAddView
          expect(@appView._renderedSubViews).to.have.length 5
          done()

        expect(@appView._renderedSubViews).to.have.length 4
        expect(@appView._visibleView).to.be.undefined
        @appView.mainMenuView.trigger 'request:pages'

    describe 'GUI stuff', ->

      it.skip 'remembers the currently focused element of a subview', (done) ->

        @appView.mainMenuView.once 'request:formAdd', =>
          @appView._visibleView.$('#transcription').focus()
          console.log @appView._visibleView.$('#transcription').prop 'tagName'
          console.log @appView._visibleView.$(':focus').prop 'tagName'
          done()

        @appView.mainMenuView.trigger 'request:formAdd'

