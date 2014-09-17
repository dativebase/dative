# global beforeEach, describe, it, assert, expect

define (require) ->

  ApplicationSettingsModel = require '../../../scripts/models/application-settings'

  describe 'Application Settings Model', ->

    before ->
      # Stub XHR: see http://sinonjs.org/docs/#server
      @xhr = sinon.useFakeXMLHttpRequest()
      requests = @requests = []
      @xhr.onCreate = (xhr) ->
        requests.push xhr
      @clock = sinon.useFakeTimers()

      sinon.spy ApplicationSettingsModel::, 'save'
      sinon.spy ApplicationSettingsModel::, 'authenticate'
      sinon.spy ApplicationSettingsModel::, 'logout'

    beforeEach ->
      @checkIfLoggedInStub = sinon.stub()
      ApplicationSettingsModel::checkIfLoggedIn = @checkIfLoggedInStub
      @appSett = new ApplicationSettingsModel()

    afterEach ->
      @checkIfLoggedInStub.reset()
      ApplicationSettingsModel::.save.reset()
      ApplicationSettingsModel::.authenticate.reset()
      ApplicationSettingsModel::.logout.reset()

    after ->
      @xhr.restore()
      @clock.restore()
      ApplicationSettingsModel::.save.restore()
      ApplicationSettingsModel::.authenticate.restore()
      ApplicationSettingsModel::.logout.restore()

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
        expect(@appSett._getURL()).to.equal 'http://localhost:8000/'

        @appSett.set 'serverURL', 'http://www.google.com'
        @appSett.set 'serverPort', ''
        expect(@appSett._getURL()).to.equal 'http://www.google.com/'

        @appSett.set 'serverPort', undefined
        expect(@appSett._getURL()).to.equal 'http://www.google.com/'

    describe 'localStorage behaviour', ->

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

        appSett = new ApplicationSettingsModel()
        expect(appSett.get('serverURL')).to.equal 'http://127.0.0.1' # default value
        appSett.fetch()
        expect(appSett.get('serverURL')).to.equal 'http://www.yahoo.com'

      it 'recognizes a URL change', ->
        expect(@appSett.checkIfLoggedIn).to.have.been.calledOnce
        serverURL = @appSett.get 'serverURL'
        serverPort = @appSett.get 'serverPort'

        # Save using extant values and expect that checkIfLoggedIn won't be called.
        @appSett.set serverURL: serverURL, serverPort: serverPort
        @appSett.save()
        expect(@appSett.checkIfLoggedIn).to.have.been.calledOnce

        # Set orthogonal values and Save and expect that checkIfLoggedIn won't be called.
        @appSett.set persistenceType: 'thingamujig'
        @appSett.save()
        expect(@appSett.checkIfLoggedIn).to.have.been.calledOnce

        # Save using a new URL and expect that checkIfLoggedIn will be called.
        @appSett.set serverURL: 'http://www.yahoo.com'
        @appSett.save()
        expect(@appSett.checkIfLoggedIn).to.have.been.calledTwice

        # Save using a new port and expect that checkIfLoggedIn will be called.
        @appSett.set serverPort: '9001'
        @appSett.save()
        expect(@appSett.checkIfLoggedIn).to.have.been.calledThrice

    describe 'RESTful behaviour', ->

      it 'makes authentication requests', ->

        # Verify that the request is as expected
        expect(@requests).to.have.length 0
        @appSett.authenticate 'fakeUsername', 'fakePassword'
        expect(@requests).to.have.length 1
        request = @requests[0]
        expect(request.method).to.equal 'POST'
        expect(JSON.parse(request.requestBody)).to.eql
          username: 'fakeUsername'
          password: 'fakePassword'
        expect(request.withCredentials).to.be.true
        expect(request.url).to.equal "#{@appSett.get(
          'serverURL')}#{@appSett.get('serverPort') and ':' +
          @appSett.get('serverPort') or ''}/login/authenticate"

        # Listen to a bunch of Backbone-wide events
        longTaskRegisterSpy = sinon.spy()
        longTaskDeregisterSpy = sinon.spy()
        authenticateEndSpy = sinon.spy()
        authenticateSuccessSpy = sinon.spy()
        authenticateFailSpy = sinon.spy()
        Backbone.on 'longTask:register', longTaskRegisterSpy
        Backbone.on 'longTask:deregister', longTaskDeregisterSpy
        Backbone.on 'authenticate:end', authenticateEndSpy
        Backbone.on 'authenticate:success', authenticateSuccessSpy
        Backbone.on 'authenticate:fail', authenticateFailSpy

        # Simulate a successful request
        @appSett.authenticate 'goodUsername', 'goodPassword'
        responseText = JSON.stringify authenticated: true
        @requests[@requests.length - 1].respond 200,
          {"Content-Type": "application/json"},
          responseText
        # All relevant events are fired except FAIL
        expect(longTaskRegisterSpy).to.have.been.calledOnce
        expect(longTaskDeregisterSpy).to.have.been.calledOnce
        expect(authenticateEndSpy).to.have.been.calledOnce
        expect(authenticateSuccessSpy).to.have.been.calledOnce
        expect(authenticateFailSpy).not.to.have.been.called
        expect(@appSett.get('username')).to.equal 'goodUsername'
        expect(@appSett.get('loggedIn')).to.be.true

        # Simulate an unsuccessful request
        @appSett.set 'loggedIn', false
        @appSett.authenticate 'goodUsername', 'goodPassword'
        responseText = JSON.stringify
          error: 'The username and password provided are not valid.'
        @requests[@requests.length - 1].respond 401,
          {"Content-Type": "application/json"},
          responseText
        # All relevant events are fired except SUCCESS
        expect(longTaskRegisterSpy).to.have.been.calledTwice
        expect(longTaskDeregisterSpy).to.have.been.calledTwice
        expect(authenticateEndSpy).to.have.been.calledTwice
        expect(authenticateSuccessSpy).to.have.been.calledOnce
        expect(authenticateFailSpy).to.have.been.calledOnce
        expect(@appSett.get('username')).to.equal 'goodUsername' # stays unchanged
        expect(@appSett.get('loggedIn')).to.be.false

        # Reset our spies. Breathe.
        longTaskRegisterSpy.reset()
        longTaskDeregisterSpy.reset()
        authenticateEndSpy.reset()
        authenticateSuccessSpy.reset()
        authenticateFailSpy.reset()

        # Simulate a response that is too slow (triggers timeout)
        ###
        # NOTE: this does NOT work, probably because Sinon's fake XHR has no timeout
        # property. (See the first link.)
        # https://github.com/cjohansen/Sinon.JS/issues/431
        # http://stackoverflow.com/questions/23360632/provoke-timeout-when-sending-ajax-request-to-sinon-fake-server
        # http://stackoverflow.com/questions/16560475/how-do-i-mock-a-timeout-or-failure-response-using-sinon-qunit
        @appSett.authenticate 'goodUsername', 'goodPassword'
        responseText = JSON.stringify authenticated: true
        @clock.tick 19000
        @requests[@requests.length - 1].respond 200,
          {"Content-Type": "application/json"},
          responseText
        # All relevant events are fired except FAIL
        expect(longTaskRegisterSpy).to.have.been.calledOnce
        expect(longTaskDeregisterSpy).to.have.been.calledOnce
        expect(authenticateEndSpy).to.have.been.calledOnce
        expect(authenticateSuccessSpy).not.to.have.been.called
        expect(authenticateFailSpy).to.have.been.calledOnce
        ###

        # Stop listening to all those Backbone-wide events
        Backbone.on 'longTask:register', longTaskRegisterSpy
        Backbone.on 'longTask:deregister', longTaskDeregisterSpy
        Backbone.on 'authenticate:end', authenticateEndSpy
        Backbone.on 'authenticate:success', authenticateSuccessSpy
        Backbone.on 'authenticate:fail', authenticateFailSpy

      it 'makes logout requests', ->

        # Verify that the logout request is as expected
        @appSett.logout()
        request = @requests[@requests.length - 1]
        expect(request.method).to.equal 'GET'
        expect(request.requestBody).to.be.null
        expect(request.withCredentials).to.be.true
        expect(request.url).to.equal "#{@appSett.get(
          'serverURL')}#{@appSett.get('serverPort') and ':' +
          @appSett.get('serverPort') or ''}/login/logout"

        # Listen to a bunch of Backbone-wide events
        longTaskRegisterSpy = sinon.spy()
        longTaskDeregisterSpy = sinon.spy()
        authenticateEndSpy = sinon.spy()
        logoutSuccessSpy = sinon.spy()
        logoutFailSpy = sinon.spy()
        Backbone.on 'longTask:register', longTaskRegisterSpy
        Backbone.on 'longTask:deregister', longTaskDeregisterSpy
        Backbone.on 'authenticate:end', authenticateEndSpy
        Backbone.on 'logout:success', logoutSuccessSpy
        Backbone.on 'logout:fail', logoutFailSpy

        # Login
        @appSett.authenticate 'goodUsername', 'goodPassword'
        responseText = JSON.stringify authenticated: true
        @requests[@requests.length - 1].respond 200,
          {"Content-Type": "application/json"},
          responseText
        expect(@appSett.get('username')).to.equal 'goodUsername'
        expect(@appSett.get('loggedIn')).to.be.true

        # Logout
        @appSett.logout()
        responseText = JSON.stringify authenticated: false
        @requests[@requests.length - 1].respond 200,
          {"Content-Type": "application/json"},
          responseText
        expect(longTaskRegisterSpy).to.have.been.calledTwice
        expect(longTaskDeregisterSpy).to.have.been.calledTwice
        expect(authenticateEndSpy).to.have.been.calledTwice
        expect(logoutSuccessSpy).to.have.been.calledOnce
        expect(logoutFailSpy).not.to.have.been.called
        expect(@appSett.get('username')).to.equal 'goodUsername' #unchanged
        expect(@appSett.get('loggedIn')).to.be.false

        # You can't really fail in a logout request from the POV of the OLD's
        # API, so I'm not going to test that...

        # Stop listening to all those Backbone-wide events
        Backbone.on 'longTask:register', longTaskRegisterSpy
        Backbone.on 'longTask:deregister', longTaskDeregisterSpy
        Backbone.on 'authenticate:end', authenticateEndSpy
        Backbone.on 'authenticate:success', logoutSuccessSpy
        Backbone.on 'authenticate:fail', logoutFailSpy

    describe 'Event responsivity', ->

      it 'responds to Backbone-wide `authenticate`-namespaced events', ->

        longTaskRegisterSpy = sinon.spy()
        authenticateLoginSpy = sinon.spy()
        Backbone.on 'longTask:register', longTaskRegisterSpy
        Backbone.on 'authenticate:login', authenticateLoginSpy

        expect(longTaskRegisterSpy).not.to.have.been.called
        expect(@appSett.authenticate).not.to.have.been.called
        expect(@appSett.logout).not.to.have.been.called
        longTaskRegisterCallCount = longTaskRegisterSpy.callCount
        authenticateCallCount = @appSett.authenticate.callCount
        logoutCallCount = @appSett.logout.callCount

        Backbone.trigger 'authenticate:login'
        # NOTE: the following two expects use `.above` because at this point there
        # will be several app settings models that have not been garbage-collected.
        # Each of these zombie models will respond to the Backbone-wide events. I
        # have not been able to figure out how to deal with this and make the tests
        # more elegant---not a big issue, but still annoying...
        expect(longTaskRegisterSpy.callCount).to.be.above longTaskRegisterCallCount
        expect(@appSett.authenticate.callCount).to.be.above authenticateCallCount
        longTaskRegisterCallCount = longTaskRegisterSpy.callCount

        Backbone.trigger 'authenticate:logout'
        expect(longTaskRegisterSpy.callCount)
          .to.be.above longTaskRegisterCallCount
        expect(@appSett.logout.callCount).to.be.above logoutCallCount

        Backbone.off 'longTask:register', longTaskRegisterSpy
        Backbone.off 'authenticate:login', authenticateLoginSpy

    describe 'Initialization', ->

      it 'checks if the user is logged in', ->
        expect(@appSett.checkIfLoggedIn).to.have.been.calledOnce
        @checkIfLoggedInStub.reset()
        expect(@appSett.checkIfLoggedIn).not.to.have.been.called
        appSett = new ApplicationSettingsModel()
        expect(@appSett.checkIfLoggedIn).to.have.been.calledOnce

