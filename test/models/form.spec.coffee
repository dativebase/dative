# global beforeEach, describe, it, assert, expect

define (require) ->

  FormModel = require('../../../scripts/models/form')
  database = require('../../../scripts/models/database')

  describe 'Form Model', ->

    describe 'General behaviour', ->

      it 'has default values', ->
        form = new FormModel()
        expect(form.get('transcription')).to.equal ''
        expect(form.get('translations')).to.be.an('array').and
          .to.be.empty
        expect(form.get('id')).to.be.null

      it 'can set values', ->
        form = new FormModel()
        form.set 'transcription', 'oki'
        form.set translations: ['hello']
        expect(form.get('transcription')).to.equal 'oki'
        expect(form.get('translations')).to.contain 'hello'

      it 'sets passed attributes', ->
        form = new FormModel(
          transcription: 'oki'
          translations: ['hello']
        )
        expect(form.get('transcription')).to.equal 'oki'
        expect(form.get('translations')).to.contain 'hello'

    describe 'OLD REST AJAX behaviour', ->

      it 'makes appropriate AJAX requests', ->
        ajaxSpy = sinon.spy()
        form = new FormModel(
          transcription: 'chien'
          translations: ['dog', 'hound']
        )
        form.sync = ajaxSpy
        expect(ajaxSpy).not.to.have.been.called
        form.save()
        expect(ajaxSpy).to.have.been.calledOnce

      it 'makes appropriate AJAX requests (stub of FormModel.sync)', ->
        sinon.stub FormModel::, 'sync'
        form = new FormModel(
          transcription: 'chien'
          translations: ['dog', 'hound']
        )
        form.save()
        expect(FormModel::.sync).to.have.been.calledOnce
        expect(FormModel::.sync).to.have.been.calledWith 'create', form
        FormModel::.sync.restore()

      it 'makes appropriate AJAX requests (stub of Backbone.sync)', ->
        sinon.stub Backbone, 'sync'
        form = new FormModel(
          transcription: 'chien'
          translations: ['dog', 'hound']
        )
        form.save()
        expect(Backbone.sync).to.have.been.calledOnce
        expect(Backbone.sync).to.have.been.calledWith 'create', form
        Backbone.sync.restore()

      it 'makes appropriate AJAX requests (with Sinon fake server)', (done) ->
        # This test illustrates how to use Sinon to inspect requests and how to
        # return fake responses.
        #
        # References:
        # - http://sinonjs.org/docs/#server
        # - http://philfreo.com/blog/how-to-unit-test-ajax-requests-with-qunit-and-sinon-js/

        # Undo backbone-indexeddb's meddling
        idbSync = Backbone.sync
        Backbone.sync = Backbone.ajaxSync

        requests = []
        xhr = sinon.useFakeXMLHttpRequest()
        xhr.onCreate = (xhr) ->
          requests.push xhr

        form = new FormModel(
          transcription: 'chien'
          translations: ['dog', 'hound']
        )
        expect(requests).to.be.empty
        form.save({}, {
          success: (model, response, options) ->
            expect(response.msg).to.equal 'Good create request!'
            done()
          ,
          error: (model, response, options) ->
            expect(false).to.be.ok
            done()
        })

        request = requests[0]
        expect(requests.length).to.equal 1
        expect(request.method).to.equal 'POST'
        expect(request.url).to.equal FormModel::.url

        requestBody = JSON.parse request.requestBody
        expect(requestBody.transcription).to.equal 'chien'
        expect(requestBody.translations).to.contain 'dog', 'hound'
        expect(requestBody.id).to.be.null

        console.log request.requestHeaders

        request.respond(200, {"Content-Type": "application/json"},
          JSON.stringify({msg: 'Good create request!'}))

        Backbone.sync = idbSync
        xhr.restore()

        done()

    describe.skip 'IndexedDB behaviour', ->

      it 'has an indexeddb database', ->
        form = new FormModel()
        expect(form.database).to.equal database

      it 'can save to indexeddb', ->
        form = new FormModel()
        form.save
            transcription: 'imitaa'
            translation: 'dog'
          ,
            success: ->
              expect(true).to.be.ok
            error: ->
              expect(false).to.be.ok

      it 'can fetch a model by id', ->
        form = new FormModel()
        form.save
            transcription: 'imitaa'
            translation: 'dog'
          ,
            success: ->
              expect(true).to.be.ok
              savedForm = new FormModel({id: form.id})
              savedForm.fetch
                success: (object) ->
                  formObject = form.toJSON()
                  savedFormObject = savedForm.toJSON()
                  expect(true).to.be.ok
                  expect(savedFormObject.transcription).to.be.equal formObject.transcription
                  expect(savedFormObject.translation).to.be.equal formObject.translation
                error: (object, error) ->
                  expect(false).to.be.ok
            error: ->
              expect(false).to.be.ok

      it 'can fetch a model by transcription index', (done) ->
        form = new FormModel()
        form.save
            transcription: 'poos'
            translation: 'dog'
          ,
            success: ->
              expect(true).to.be.ok
              savedForm = new FormModel({transcription: form.get('transcription')})
              savedForm.fetch
                success: (object) ->
                  formObject = form.toJSON()
                  savedFormObject = savedForm.toJSON()
                  expect(true).to.be.ok
                  expect(savedFormObject.transcription).to.be.equal formObject.transcription
                  expect(savedFormObject.translation).to.be.equal formObject.translation
                  done()
                error: (object, error) ->
                  expect(false).to.be.ok
                  done()
            error: ->
              expect(false).to.be.ok
              done()

      it 'can not fetch a model by a non-index: translation', (done) ->
        form = new FormModel()
        form.save
            transcription: 'foo'
            translation: 'bar'
          ,
            success: ->
              expect(true).to.be.ok
              savedForm = new FormModel({translation: form.get('translation')})
              savedForm.fetch
                success: (object) ->
                  expect(false).to.be.ok
                  done()
                error: (object, error) ->
                  # We expect an error because the translation attribute is not
                  # indexed
                  expect(true).to.be.ok
                  done()
            error: ->
              expect(false).to.be.ok
              done()

      it 'can update a form model', (done) ->
        form = new FormModel()
        form.save
            transcription: 'bar'
            translation: 'baz'
          ,
            success: ->
              expect(form.toJSON().transcription).to.equal 'bar'
              form.save
                  transcription: 'foo'
                ,
                  success: ->
                    form.fetch
                      success: (object) ->
                        expect(form.toJSON().transcription).to.equal 'foo'
                        expect(form.toJSON().translation).to.equal 'baz'
                        done()
                      error: (object, error) ->
                        expect(false).to.be.ok
                        done()
                  error: ->
                    expect(false).to.be.ok
                    done()
            error: (object, error) ->
              expect(false).to.be.ok
              done()

      it 'can delete a form model', (done) ->
        form = new FormModel()
        form.save
            transcription: 'foo'
            translation: 'bar'
          ,
            success: (object) ->
              expect(true).to.be.ok
              form.destroy
                success: ->
                  expect(true).to.be.ok
                  form.fetch
                    success: ->
                      expect(false).to.be.ok # shouldn't be able to fetch deleted
                      done()
                    error: (object, error) ->
                      expect(error).to.equal 'Not Found'
                      done()
                error: (object, error) ->
                  expect(false).to.be.ok # should be able to destroy
                  done()
            error: (error) ->
              expect(false).to.be.ok # should be able to save
              done()

    describe.skip 'Relational Backbone behaviour', ->

      it 'can be converted to a relational data structure', ->

