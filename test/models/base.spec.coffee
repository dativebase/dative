define (require) ->

  BaseModel = require('../../../scripts/models/base')

  describe 'Base Model', ->

    before ->
      # Stub XHR: see http://sinonjs.org/docs/#server
      @xhr = sinon.useFakeXMLHttpRequest()
      requests = @requests = []
      @xhr.onCreate = (xhr) ->
        requests.push xhr

    beforeEach ->
      @baseModel = new BaseModel()

    after ->
      @xhr.restore()

    it 'can perform a CORS request', ->
      onload = sinon.spy()
      onerror = sinon.spy()
      url = 'http://www.google.com'
      expect(@requests).to.have.length 0
      @baseModel.cors
        url: url
        onload: onload
        onerror: onerror
      expect(@requests).to.have.length 1
      request = @requests[0]
      expect(request.method).to.equal 'GET'
      expect(request.requestBody).to.be.null
      expect(request.withCredentials).to.be.true
      expect(request.url).to.equal url

      msg = msg: 'a JSON message from Google!'
      @requests[@requests.length - 1].respond 200,
        {"Content-Type": "application/json"},
        JSON.stringify msg
      expect(onload).to.have.been.calledOnce
      expect(onerror).not.to.have.been.called
      expect(onload).to.have.been.calledWith msg # BaseModel._jsonify turns this into an object.

      @baseModel.cors
        url: url
        onload: onload
        onerror: onerror

      # Note that the `onerror` callback is NOT called with a 4/500 status code...
      # Here I make the response return invalid JSON. The _jsonify wrapper in
      # base.coffee handles this by passing on the response body as is.
      msg = JSON.stringify(msg: 'failface')[..-3]
      @requests[@requests.length - 1].respond 500,
        {"Content-Type": "application/json"},
        msg
      expect(onload).to.have.been.calledTwice
      expect(onload).to.have.been.calledWith msg
      expect(onerror).not.to.have.been.called

