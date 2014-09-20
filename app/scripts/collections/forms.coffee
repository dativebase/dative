define [
    'backbone',
    './../models/form'
    './../models/database'
    'backboneindexeddb'
  ], (Backbone, FormModel, database) ->

    class FormsCollection extends Backbone.Collection

      # Backbone-IndexedDB stuff
      database: database
      storeName: 'forms'
      model: FormModel
      url: 'http://127.0.0.1:5002'

      # Overriding `fetch` (for now...)
      fetch: (options) ->
        @_fakeFetch()
        #@_corsFetch()

      _fakeFetch: ->
        fakeFormModel1 = new @model
          transcription: 'chien'
          translations: [
              transcription: 'dog'
            ,
              transcription: 'hound'
            ,
              transcription: 'wolf'
              grammaticality: '*'
          ]
        fakeFormModel2 = new @model
          transcription: 'chat'
          translations: [transcription: 'cat']
        @set [fakeFormModel1, fakeFormModel2]

      _corsFetch: ->

        # TODO: read this: http://stackoverflow.com/questions/14376295/should-i-simulate-a-cors-options-request-in-sinon-js-or-how-do-i-test-cross-doma

        url = "#{@url}/forms"
        method = 'GET'
        payload = null

        fetchType = 'authenticate'
        if fetchType is 'authenticate'
          url = 'http://127.0.0.1:5000/login/authenticate'
          method = 'POST'
          payload = JSON.stringify(username: 'dative-rest-username', password: 'password')
        else if fetchType is 'forms_new'
          url = 'http://127.0.0.1:5000/forms/new'
        console.log url
        xhr = @model::createCORSRequest method, url
        if not xhr
          throw new Error 'CORS not supported'
        xhr.withCredentials = true
        xhr.send(payload)

        console.log 'I made a request'
        xhr.onload = ->
          console.log 'onload fired'
          responseText = xhr.responseText
          console.log responseText

          # TODO: process the response.

        xhr.onerror = ->
          console.log 'onerror: there was an error!'

        xhr.onloadstart = ->
          console.log 'onloadstart: the request has started'

        xhr.onabort = ->
          console.log 'onabort: the request has been aborted. For instance, by
            invoking the abort() method.'

        xhr.onprogress = ->
          console.log 'onprogress: while loading and sending data.'

        xhr.ontimeout = ->
          console.log 'ontimeout: author-specified timeout has passed before the
            request could complete.'

        xhr.onloadend = ->
          console.log 'onloadend: the request has completed (either in success
            or failure).'

