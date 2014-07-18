# global beforeEach, describe, it, assert, expect

define (require) ->

  database = require '../../../scripts/models/database'
  LingSyncIDB = require '../../../scripts/utils/indexeddb-utils'

  databaseId = database.id # 'lingsync-database'
  databaseVersion = database.migrations[..].pop().version # 1
  lingSyncIDB = new LingSyncIDB databaseId, databaseVersion

  describe 'LingSyncIDB Class', ->

    it 'can open a connection to the indexedDB database', (done) ->
      expect(lingSyncIDB.datastore).to.be.null
      lingSyncIDB.open ->
        expect(lingSyncIDB.datastore).is.an.instanceof IDBDatabase
        expect(v for k, v of lingSyncIDB.datastore.objectStoreNames).to.contain(
          'forms')
        done()

    it 'can create a form in the indexedDB dataStore', (done) ->
      lingSyncIDB.open ->
        lingSyncIDB.createForm {transcription: 'monkey', translation: 'singe'},
          (formObject) ->
            expect(formObject.transcription).to.equal 'monkey'
            done()

###
    it 'can fetch all forms in the indexedDB dataStore', (done) ->
      lingSyncIDB = new LingSyncIDB databaseId, databaseVersion
      lingSyncIDB.open ->
        lingSyncIDB.createForm {transcription: 'monkey', translation: 'singe'},
          (formObject) ->
            expect(formObject.transcription).to.equal 'monkey'
            done()
###

