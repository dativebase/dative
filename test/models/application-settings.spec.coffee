# global beforeEach, describe, it, assert, expect

define (require) ->

  ApplicationSettingsModel = require '../../../scripts/models/application-settings'

  describe 'Application Settings Model', ->

    before ->
      sinon.spy ApplicationSettingsModel::, 'save'

    beforeEach ->
      # We stub the checkIfLoggedIn method of the app settings model just so that
      # the console isn't filled with failed CORS requests.
      @checkIfLoggedInStub = sinon.stub()
      @authenticateStub = sinon.stub()
      @logoutStub = sinon.stub()
      ApplicationSettingsModel::checkIfLoggedIn = @checkIfLoggedInStub
      ApplicationSettingsModel::authenticate = @authenticateStub
      ApplicationSettingsModel::logout = @logoutStub
      @appSett = new ApplicationSettingsModel()

    afterEach ->
      @checkIfLoggedInStub.reset()
      @authenticateStub.reset()
      @logoutStub.reset()
      ApplicationSettingsModel::.save.reset()

    after ->
      ApplicationSettingsModel::.save.restore()

    describe 'General behaviour', ->

      it 'has default values', ->
        expect(@appSett.get('serverURL')).to.equal 'http://127.0.0.1'
        expect(@appSett.get('serverPort')).to.equal '5000'

      it 'can set values', ->
        appSett = new ApplicationSettingsModel()
        @appSett.set 'serverURL', 'http://www.google.com/'
        expect(@appSett.get('serverURL')).to.equal 'http://www.google.com/'

      it 'sets passed attributes', ->
        @appSett = new ApplicationSettingsModel(
          'serverURL': 'http://127.0.0.1'
          'serverPort': '5000'
        )
        expect(@appSett.get('serverURL')).to.equal 'http://127.0.0.1'
        expect(@appSett.get('serverPort')).to.equal '5000'

      it 'assembles a full URL from `serverURL` and `serverPort`', ->
        @appSett.set 'serverURL', 'http://localhost'
        @appSett.set 'serverPort', '8000'
        expect(@appSett.getURL()).to.equal 'http://localhost:8000/'

        @appSett.set 'serverURL', 'http://www.google.com'
        @appSett.set 'serverPort', ''
        expect(@appSett.getURL()).to.equal 'http://www.google.com/'

        @appSett.set 'serverPort', undefined
        expect(@appSett.getURL()).to.equal 'http://www.google.com/'

    describe 'localStorage behaviour', ->

      it 'records if the URL has changed', ->
        expect(@appSett.checkIfLoggedIn).to.have.been.calledOnce
        serverURL = @appSett.get 'serverURL'
        serverPort = @appSett.get 'serverPort'

        # Save using extant values and expect that checkIfLoggedIn won't be called.
        @appSett.set serverURL: serverURL, serverPort: serverPort
        @appSett.save()
        expect(@appSett.checkIfLoggedIn).to.have.been.calledOnce

        # Save using new values and expect that checkIfLoggedIn will be called.
        @appSett.set serverURL: 'http://www.yahoo.com', serverPort: serverPort
        @appSett.save()
        expect(@appSett.checkIfLoggedIn).to.have.been.calledTwice

      it 'saves to localStorage', ->
        localStorage.removeItem 'dativeApplicationSettings'
        expect(localStorage.getItem('dativeApplicationSettings')).to.be.null
        @appSett = new ApplicationSettingsModel()
        expect(localStorage.getItem('dativeApplicationSettings')).to.be.null
        @appSett.set()
        expect(localStorage.getItem('dativeApplicationSettings')).to.be.null
        @appSett.save()
        expect(JSON.parse(localStorage.getItem('dativeApplicationSettings')))
          .to.eql @appSett.attributes

        @appSett.set 'serverURL', 'http://www.yahoo.com'
        @appSett.save()
        expect(JSON.parse(localStorage.getItem('dativeApplicationSettings'))
          .serverURL).to.equal 'http://www.yahoo.com'

    describe 'Event responsivity', ->

      it 'responds to Backbone-wide `authenticate`-namespaced events', ->
        expect(@appSett.authenticate).not.to.have.been.called
        expect(@appSett.logout).not.to.have.been.called
        Backbone.trigger 'authenticate:login'
        expect(@appSett.authenticate).to.have.been.calledOnce
        Backbone.trigger 'authenticate:logout'
        expect(@appSett.logout).to.have.been.calledOnce

    describe 'Initialization', ->

      it 'checks if the user is logged in'


