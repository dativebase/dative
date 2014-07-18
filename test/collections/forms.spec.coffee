# global beforeEach, describe, it, assert, expect

define (require) ->

  FormModel = require '../../../scripts/models/form'
  FormsCollection = require '../../../scripts/collections/forms'
  database = require '../../../scripts/models/database'

  # Recursive function to delete all models in a collection.
  # Taken from the indexeddb-backbonejs-adapter
  deleteNext = (coll, done) ->
    if coll.length is 0
      done()
    else
      form = coll.pop()
      form.destroy
        success: ->
          deleteNext coll, done
        error: ->
          deleteNext coll, done

  describe 'Forms Collection', ->

    describe 'IndexedDB behaviour', ->

      #@timeout 10000

      it 'can delete all of its form models', (done) ->
        forms = new FormsCollection()
        forms.fetch
          success: ->
            deleteNext forms, ->
              expect(forms.models.length).to.equal 0
              done()
          error: ->
            expect(false).to.be.ok
            console.log 'unable to fetch forms collection'
            done()

      it 'has an indexeddb database', (done) ->
        forms = new FormsCollection()
        forms.fetch
          success: ->
            expect(forms.models.length).to.equal 0
            done()
          error: ->
            console.log 'error'
            expect(false).to.be.ok
            done()

