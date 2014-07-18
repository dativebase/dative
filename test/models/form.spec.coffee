# global beforeEach, describe, it, assert, expect

define (require) ->

  FormModel = require('../../../scripts/models/form')
  database = require('../../../scripts/models/database')

  describe 'Form Model', ->

    describe 'General behaviour', ->

      it 'has default values', ->
        form = new FormModel()
        expect(form.get('transcription')).to.equal ''
        expect(form.get('translation')).to.equal ''
        expect(form.get('schemaType')).to.equal 'relational'
        expect(form.get('storageType')).to.equal 'local'

      it 'can set values', ->
        form = new FormModel()
        form.set('transcription', 'oki')
        form.set {translation: 'hello', schemaType: 'norel'}
        expect(form.get('transcription')).to.equal 'oki'
        expect(form.get('translation')).to.equal 'hello'
        expect(form.get('schemaType')).to.equal 'norel'

    describe 'IndexedDB behaviour', ->

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

    describe 'Relational Backbone behaviour', ->

      it 'can be converted to a relational data structure', ->

#508


