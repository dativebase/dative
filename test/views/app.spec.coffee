# What we want to test:
#
# - Views can render the target HTML, binding model data to a template string
# - View objects provided with an el property get added to thehe DOM on creation
# - View methods correctly bind to DOM and Backbone.js events, and respond appropriately
# - Objects contained by a view (formor example, subviews and models) are properly disposed on the view removal

define (require) ->

  AppView = require '../../../scripts/views/app'

  describe 'App View', ->

    before ->
      # Create test fixture.
      @$fixture = $("<div id='app-view-fixture'></div>")

    beforeEach ->
      # Empty out and rebind the fixture for each run.
      @$fixture.empty().appendTo $('#fixtures')

      # New default model and view for each test
      @appView = new AppView el: @$fixture

    afterEach ->
      @appView.remove()

    after ->
      $('#fixtures').empty()

    it 'renders its persistent sub-views', ->
      $mainmenu = $ '#mainmenu'
      $progressWidgetContainer = $ '#progress-widget-container'
      $notifierContainer = $ '#notifier-container'
      $appView = $ '#appview'
      $loginDialog = $ 'div.dative-login-dialog'

      # Test that the main menu, progress widget, container widget, and login
      # dialog are rendered as expected.
      mainmenuFirstChild = $mainmenu.children().first()
      expect(mainmenuFirstChild.prop('tagName')).to.equal 'UL'
      expect(mainmenuFirstChild.hasClass('sf-menu')).to.be.true

      progressFirstChild = $progressWidgetContainer.children().first()
      expect(progressFirstChild.prop('tagName')).to.equal 'DIV'
      expect(progressFirstChild.hasClass('progress-widget')).to.be.true

      expect($notifierContainer.html()).to.equal ''
      expect($appView.html()).to.equal ''

      loginDialogFirstChild = $loginDialog.children().first()
      expect(loginDialogFirstChild.prop('tagName')).to.equal 'FORM'
      expect(loginDialogFirstChild.hasClass('loginLogin')).to.be.true

    it 'renders app views in response to main menu events', (done) ->
      @appView.mainMenuView.once('request:pages', =>
        expect(@appView.$('div.dative-page-header-title').text())
          .to.equal 'Pages'
        @appView.mainMenuView.trigger 'request:formAdd'
      )

      @appView.mainMenuView.once('request:formAdd', =>
        expect(@appView.$('div.dative-page-header-title').text())
          .to.equal 'Add a Form'
        done()
      )

      @appView.mainMenuView.trigger 'request:pages'

    it 'makes visible the login dialog box', (done) ->
      @appView.mainMenuView.once('request:openLoginDialogBox', =>
        $loginDialog = $ 'div.dative-login-dialog'
        expect($loginDialog.dialog('isOpen')).to.be.true
        $loginDialog.dialog 'close' # Gotta close it so it doesn't pollute the mocha tests page (really this is a bug, the login dialog should NOT be appended to the <body>.
        done()
      )

      $loginDialog = $ 'div.dative-login-dialog'
      expect($loginDialog.dialog('isOpen')).to.be.false
      @appView.mainMenuView.trigger 'request:openLoginDialogBox'

# TODO
# Use the Chai plugins for Backbone and jQuery!
# - see p. 89 of Backbone Testing
# - see http://chaijs.com/ plugins/chai-backbone
# - see http://chaijs.com/ plugins/chai-jquery

