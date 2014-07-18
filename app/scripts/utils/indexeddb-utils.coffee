###
  Functionality for interacting with IndexedDB.

  Based heavily upon Matt West's IndexedDB example todo application:

      http://blog.teamtreehouse.com/create-your-own-to-do-app-with-html5-and-indexeddb

  Defines a LingSyncIDB class that simplifies IndexedDB interactions.

###

define (require) ->

  class LingSyncIDB

    constructor: (@id, @version) ->
      @indexedDB = window.indexedDB or window.webkitIndexedDB or \
        window.mozIndexedDB or window.msIndexedDB
      @datastore = null

    s4: ->
      (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1

    guid: ->
      "#{@s4()}#{@s4()}-#{@s4()}-#{@s4()}-#{@s4()}-#{@s4()}#{@s4()}#{@s4()}"

    # Open a connection to the datastore
    open: (callback) ->
      request = @indexedDB.open @id, @version

      # Handle datastore upgrades.
      request.onupgradeneeded = (e) ->
        db = e.target.result
        e.target.transaction.onerror = @onerror
        if db.objectStoreNames.contains 'forms'
          db.deleteObjectStore 'forms'
        #store = db.createObjectStore 'forms', keyPath: 'timestamp'
        store = db.createObjectStore 'forms'

      # Handle successful datastore access.
      request.onsuccess = (e) =>
        @datastore = e.target.result
        callback()

      # Handle errors when opening the datastore.
      request.onerror = ->
        callback false

    # Fetch all of the form items in the datastore.
    #   @param {function} callback A function that will be executed once the items
    #   have been retrieved. Will be passed a param with an array of the form
    #   items.
    fetchForms: (callback) ->
      db = @datastore
      transaction = db.transaction ['forms'], 'readwrite'
      objStore = transaction.objectStore 'forms'
      keyRange = IDBKeyRange.lowerBound 0
      cursorRequest = objStore.openCursor keyRange
      forms = []

      transaction.oncomplete = (e) ->
        # Execute the callback function.
        callback forms

      cursorRequest.onsuccess = (e) ->
        result = e.target.result
        if not result
          return
        forms.push result.value
        result.continue()

      cursorRequest.onerror = @onerror

    # Create a new form item.
    #   @param {object} formObject The form data.
    createForm: (formObject, callback) ->
      # Get a reference to the db.
      db = @datastore
      # Initiate a new transaction.
      transaction = db.transaction ['forms'], 'readwrite'
      # Get the datastore.
      objStore = transaction.objectStore 'forms'
      # Create a timestamp for the form item.
      timestamp = new Date().getTime()

      # Create an object for the form item.
      formObject.timestamp = timestamp
      formObject.id = @guid()

      # Create the datastore request.
      request = objStore.put formObject, formObject.id

      # Handle a successful datastore put.
      request.onsuccess = (e) ->
        # Execute the callback function.
        callback formObject

      # Handle errors.
      request.onerror = @onerror

    # Delete a form item.
    #   @param {int} id The timestamp (id) of the form item to be deleted.
    #   @param {function} callback A callback function that will be executed if
    #   the delete is successful.
    deleteForm: (id, callback) ->
      db = @datastore
      transaction = db.transaction ['forms'], 'readwrite'
      objStore = transaction.objectStore 'forms'
      request = objStore.delete id

      request.onsuccess = (e) ->
        callback()

      request.onerror = (e) ->
        console.log e

    # General error handler
    onerror: ->
      console.log 'Generic LingSyncIDB error method called'

    # Delete entire indexedDB database.
    # FIXME: this messes up the indexedDB database in ways I don't understand...
    deleteDatabase: (callback) ->
      try
        request = @indexedDB.deleteDatabase @id
        request.onsuccess = (event) ->
          db = event.result
          callback true
        request.onerror = (event) ->
          console.error "indexedDB.delete Error: #{event.message}"
          callback false
      catch e
        console.error "Error: #{e.message}"
        # prefer change id of database than to start on new instance
        @id = @id + '.' + @guid()
        callback false


