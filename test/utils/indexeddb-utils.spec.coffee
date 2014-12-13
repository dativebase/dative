# global beforeEach, describe, it, assert, expect

define (require) ->

  database = require '../../../scripts/models/database'
  {FieldDBIDB, FormStore} = require '../../../scripts/utils/indexeddb-utils'
  {clone} = require '../../../scripts/utils/utils'

  databaseId = database.id # 'fielddb-database'
  databaseVersion = database.migrations[..].pop().version # 1
  fieldDBIDB = new FieldDBIDB databaseId, databaseVersion


  describe 'FieldDBIDB class', ->

    @timeout 10000

    # Optimist handler: unbridled success!
    optimistHandler =
      onsuccess: ->
        expect(true).to.be.ok
      onerror: ->
        expect(false).to.be.ok

    it 'can open a connection to the indexedDB database', (done) ->

      expect(fieldDBIDB.datastore).to.be.null

      # An open database has an appropriate datastore attribute
      openHandler = _.extend (clone optimistHandler),
        onsuccess: ->
          expect(fieldDBIDB.datastore).is.an.instanceof IDBDatabase
          expect(v for k, v of fieldDBIDB.datastore.objectStoreNames)
            .to.contain 'forms'
          done()

      fieldDBIDB.open openHandler

    it 'can create a form', (done) ->

      createHandler = _.extend (clone optimistHandler),
        onsuccess: (formObject) ->
          expect(formObject.transcription).to.equal 'monkey'
          done()

      fieldDBIDB.create(
        {transcription: 'monkey', translation: 'singe'},
        createHandler,
        storeName: 'forms'
      )

    it 'can retrieve all forms', (done) ->

      # Count forms initially, request create
      indexHandler = _.extend (clone optimistHandler),
        onsuccess: (formsArray) =>
          @initialCount = formsArray.length
          fieldDBIDB.create(
            {transcription: 'dog', translation: 'chien'},
            createHandler, storeName: 'forms')

      # Store created form, create another
      createHandler = _.extend (clone optimistHandler),
        onsuccess: (formObject) =>
          expect(formObject.transcription).to.equal 'dog'
          fieldDBIDB.create(
            {transcription: 'cat', translation: 'chat'},
            createHandler2, storeName: 'forms')

      # Store created form, request all again
      createHandler2 = _.extend (clone optimistHandler),
        onsuccess: (formObject) =>
          expect(formObject.transcription).to.equal 'cat'
          fieldDBIDB.index indexHandler2, storeName: 'forms'

      # Count forms now, request delete
      indexHandler2 = _.extend (clone optimistHandler), 
        onsuccess: (formsArray) =>
          @afterCreateCount = formsArray.length
          expect(@afterCreateCount - @initialCount).to.equal 2
          done()

      # Start by requesting all forms
      fieldDBIDB.index indexHandler, storeName: 'forms'

    it 'can retrieve a specific form', (done) ->

      # Count forms initially, request create
      indexHandler = _.extend (clone optimistHandler),
        onsuccess: (formsArray) =>
          @initialCount = formsArray.length
          fieldDBIDB.create(
            {transcription: 'dog', translation: 'chien'},
            createHandler, storeName: 'forms')

      # Store created form, create another
      createHandler = _.extend (clone optimistHandler),
        onsuccess: (formObject) =>
          @firstForm = formObject
          expect(formObject.transcription).to.equal 'dog'
          fieldDBIDB.create(
            {transcription: 'cat', translation: 'chat'},
            createHandler2, storeName: 'forms')

      # Store created form, retrieve the first one created
      createHandler2 = _.extend (clone optimistHandler),
        onsuccess: (formObject) =>
          expect(formObject.transcription).to.equal 'cat'
          fieldDBIDB.show @firstForm.id, showHandler, storeName: 'forms'

      # Expect correct form to have been retrieved
      showHandler = _.extend (clone optimistHandler),
        onsuccess: (form) =>
          expect(form.transcription).to.equal @firstForm.transcription
          done()

      # Start by requesting all forms
      fieldDBIDB.index indexHandler, storeName: 'forms'

    it 'can update a form', (done) ->

      # Store created form, then update it
      createHandler = _.extend (clone optimistHandler),
        onsuccess: (formObject) =>
          @initialForm = formObject
          expect(formObject.transcription).to.equal 'our form'
          fieldDBIDB.index indexHandler, storeName: 'forms'

      # Count forms, request update
      indexHandler = _.extend (clone optimistHandler),
        onsuccess: (formsArray) =>
          @afterCreateCount = formsArray.length
          updatedForm = _.extend @initialForm, transcription: 'our form modified'
          fieldDBIDB.update(@initialForm.id, updatedForm, updateHandler,
            storeName: 'forms')

      # Request form count
      updateHandler = _.extend (clone optimistHandler),
        onsuccess: (updatedFormObject) =>
          expect(updatedFormObject.transcription).to.equal 'our form modified'
          fieldDBIDB.index indexHandler2, storeName: 'forms'

      # Verify form count has not changed
      indexHandler2 = _.extend (clone optimistHandler),
        onsuccess: (formsArray) =>
          expect(formsArray.length).to.equal @afterCreateCount
          done()

      # Start by creating a form
      fieldDBIDB.create(
        {transcription: 'our form', translation: 'notre forme'},
        createHandler,
        storeName: 'forms'
      )

    it 'can delete a form', (done) ->

      # Count forms initially, request create
      indexHandler = _.extend (clone optimistHandler),
        onsuccess: (formsArray) =>
          @initialCount = formsArray.length
          fieldDBIDB.create(
            {transcription: 'monkey', translation: 'singe'},
            createHandler,
            storeName: 'forms'
          )

      # Store created form, request all forms
      createHandler = _.extend (clone optimistHandler),
        onsuccess: (formObject) =>
          @ourForm = formObject
          expect(formObject.transcription).to.equal 'monkey'
          fieldDBIDB.index indexHandler2, storeName: 'forms'

      # Count forms now, request delete
      indexHandler2 = _.extend (clone optimistHandler), 
        onsuccess: (formsArray) =>
          @afterCreateCount = formsArray.length
          fieldDBIDB.delete @ourForm.id, deleteHandler, storeName: 'forms'

      # Request form count
      deleteHandler = _.extend (clone optimistHandler),
        onsuccess: (formObject) =>
          fieldDBIDB.index indexHandler3, storeName: 'forms'

      # Verify counts
      indexHandler3 = _.extend (clone optimistHandler),
        onsuccess: (formsArray) =>
          expect(@initialCount + 1).to.equal @afterCreateCount
          expect(@afterCreateCount - 1).to.equal formsArray.length
          expect(@initialCount).to.equal formsArray.length
          done()

      # Start by requesting all forms
      fieldDBIDB.index indexHandler, storeName: 'forms'

    it 'can delete all forms', (done) ->

      # Count forms initially, proceed to delete all
      indexHandler = _.extend (clone optimistHandler),
        onsuccess: (formsArray) =>
          @initialCount = formsArray.length
          @initialForms = formsArray
          deleteAllForms()

      # Delete all, request all
      deleteAllForms = =>
        for form in @initialForms
          fieldDBIDB.delete form.id, optimistHandler, storeName: 'forms'
        fieldDBIDB.index indexHandler2, storeName: 'forms'

      # Count forms now, expect none
      indexHandler2 = _.extend (clone optimistHandler),
        onsuccess: (formsArray) =>
          expect(formsArray).to.have.length 0
          done()

      # Start by requesting all forms
      fieldDBIDB.index indexHandler, storeName: 'forms'




  describe 'FormStore class', ->

    formStore = new FormStore fieldDBIDB

    @timeout 1000

    # Optimist handler: unbridled success!
    optimistHandler =
      onsuccess: ->
        expect(true).to.be.ok
      onerror: ->
        expect(false).to.be.ok

    it 'can create a form', (done) ->

      createHandler = _.extend (clone optimistHandler),
        onsuccess: (formObject) ->
          expect(formObject.transcription).to.equal 'monkey'
          done()

      formStore.create(
        {transcription: 'monkey', translation: 'singe'},
        createHandler
      )

    it 'can retrieve all forms', (done) ->

      # Count forms initially, request create
      indexHandler = _.extend (clone optimistHandler),
        onsuccess: (formsArray) =>
          @initialCount = formsArray.length
          formStore.create(
            {transcription: 'dog', translation: 'chien'},
            createHandler)

      # Store created form, create another
      createHandler = _.extend (clone optimistHandler),
        onsuccess: (formObject) =>
          expect(formObject.transcription).to.equal 'dog'
          formStore.create(
            {transcription: 'cat', translation: 'chat'},
            createHandler2)

      # Store created form, request all again
      createHandler2 = _.extend (clone optimistHandler),
        onsuccess: (formObject) =>
          expect(formObject.transcription).to.equal 'cat'
          formStore.index indexHandler2

      # Count forms now, request delete
      indexHandler2 = _.extend (clone optimistHandler), 
        onsuccess: (formsArray) =>
          @afterCreateCount = formsArray.length
          expect(@afterCreateCount - @initialCount).to.equal 2
          done()

      # Start by requesting all forms
      formStore.index indexHandler

    it 'can retrieve a specific form', (done) ->

      # Count forms initially, request create
      indexHandler = _.extend (clone optimistHandler),
        onsuccess: (formsArray) =>
          @initialCount = formsArray.length
          formStore.create(
            {transcription: 'dog', translation: 'chien'},
            createHandler)

      # Store created form, create another
      createHandler = _.extend (clone optimistHandler),
        onsuccess: (formObject) =>
          @firstForm = formObject
          expect(formObject.transcription).to.equal 'dog'
          formStore.create(
            {transcription: 'cat', translation: 'chat'},
            createHandler2)

      # Store created form, retrieve the first one created
      createHandler2 = _.extend (clone optimistHandler),
        onsuccess: (formObject) =>
          expect(formObject.transcription).to.equal 'cat'
          formStore.show @firstForm.id, showHandler

      # Expect correct form to have been retrieved
      showHandler = _.extend (clone optimistHandler),
        onsuccess: (form) =>
          expect(form.transcription).to.equal @firstForm.transcription
          done()

      # Start by requesting all forms
      formStore.index indexHandler

    it 'can update a form', (done) ->

      # Store created form, then update it
      createHandler = _.extend (clone optimistHandler),
        onsuccess: (formObject) =>
          @initialForm = formObject
          expect(formObject.transcription).to.equal 'our form'
          formStore.index indexHandler

      # Count forms, request update
      indexHandler = _.extend (clone optimistHandler),
        onsuccess: (formsArray) =>
          @afterCreateCount = formsArray.length
          updatedForm = _.extend @initialForm, transcription: 'our form modified'
          formStore.update @initialForm.id, updatedForm, updateHandler

      # Request form count
      updateHandler = _.extend (clone optimistHandler),
        onsuccess: (updatedFormObject) =>
          expect(updatedFormObject.transcription).to.equal 'our form modified'
          formStore.index indexHandler2

      # Verify form count has not changed
      indexHandler2 = _.extend (clone optimistHandler),
        onsuccess: (formsArray) =>
          expect(formsArray.length).to.equal @afterCreateCount
          done()

      # Start by creating a form
      formStore.create(
        {transcription: 'our form', translation: 'notre forme'},
        createHandler
      )

    it 'can delete a form', (done) ->

      # Count forms initially, request create
      indexHandler = _.extend (clone optimistHandler),
        onsuccess: (formsArray) =>
          @initialCount = formsArray.length
          formStore.create(
            {transcription: 'monkey', translation: 'singe'},
            createHandler
          )

      # Store created form, request all forms
      createHandler = _.extend (clone optimistHandler),
        onsuccess: (formObject) =>
          @ourForm = formObject
          expect(formObject.transcription).to.equal 'monkey'
          formStore.index indexHandler2

      # Count forms now, request delete
      indexHandler2 = _.extend (clone optimistHandler), 
        onsuccess: (formsArray) =>
          @afterCreateCount = formsArray.length
          formStore.delete @ourForm.id, deleteHandler

      # Request form count
      deleteHandler = _.extend (clone optimistHandler),
        onsuccess: (formObject) =>
          formStore.index indexHandler3

      # Verify counts
      indexHandler3 = _.extend (clone optimistHandler),
        onsuccess: (formsArray) =>
          expect(@initialCount + 1).to.equal @afterCreateCount
          expect(@afterCreateCount - 1).to.equal formsArray.length
          expect(@initialCount).to.equal formsArray.length
          done()

      # Start by requesting all forms
      formStore.index indexHandler

    it 'can delete all forms', (done) ->

      # Count forms initially, proceed to delete all
      indexHandler = _.extend (clone optimistHandler),
        onsuccess: (formsArray) =>
          @initialCount = formsArray.length
          @initialForms = formsArray
          deleteAllForms()

      # Delete all, request all
      deleteAllForms = =>
        for form in @initialForms
          formStore.delete form.id, optimistHandler
        formStore.index indexHandler2

      # Count forms now, expect none
      indexHandler2 = _.extend (clone optimistHandler),
        onsuccess: (formsArray) =>
          expect(formsArray).to.have.length 0
          done()

      # Start by requesting all forms
      formStore.index indexHandler

