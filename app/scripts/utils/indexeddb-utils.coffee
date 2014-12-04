# Functionality for interacting with IndexedDB.
#
# Based heavily upon Matt West's IndexedDB example todo application:
#
#     http://blog.teamtreehouse.com/create-your-own-to-do-app-with-html5-and-indexeddb
#
# Defines a FieldDBIDB class that simplifies IndexedDB interactions.
#
# See also the IndexedDB API spec:
#
#    http://www.w3.org/TR/IndexedDB/
#
# API to implement (basically a rewrite of the OLD's Atom-based API)
# search {query: {filter: [], order_by: []}, paginator: {}}
# new_search
# index (get all; order_by and pagination params, optional)
# create :param Object form:
# update :param Number id: :param Object form:
# delete :param Number id:
# show :param Number id:

define (require) ->

  {clone} = require './utils'

  # A wrapper around IndexedDB with FieldDB conveniences.
  class FieldDBIDB

    # :param String id: name of the IndexedDB database as defined in
    #   `models/database`.
    # :param String version: IDB version, for migrations.
    constructor: (@id, @version) ->
      @indexedDB = window.indexedDB or window.webkitIndexedDB or \
        window.mozIndexedDB or window.msIndexedDB
      @IDBKeyRange = window.IDBKeyRange or window.webkitIDBKeyRange
      @datastore = null

    s4: ->
      (((1 + Math.random()) * 0x10000) | 0).toString(16).substring 1

    guid: ->
      "#{@s4()}#{@s4()}-#{@s4()}-#{@s4()}-#{@s4()}-#{@s4()}#{@s4()}#{@s4()}"

    # Open a connection to the datastore
    open: (handler) ->
      if @datastore instanceof IDBDatabase
        return handler.onsuccess()
      request = @indexedDB.open @id, @version

      # Handle datastore upgrades.
      # TODO: write tests to handle upgrades
      request.onupgradeneeded = (event) ->
        db = event.target.result
        event.target.transaction.onerror = handler.onerror
        if db.objectStoreNames.contains 'forms'
          db.deleteObjectStore 'forms'
        store = db.createObjectStore 'forms'

      request.onsuccess = (event) =>
        @datastore = event.target.result
        handler.onsuccess()
      request.onerror = handler.onerror

    defaultHandler:
      onsuccess: (->)
      onerror: (->)

    # Retrieve a single item via its key.
    show: (key, handler, options) ->
      @open @defaultHandler
      transaction = @datastore.transaction [options.storeName], 'readwrite'
      objStore = transaction.objectStore options.storeName
      request = objStore.get key
      request.onsuccess = (event) ->
        handler.onsuccess event.target.result
      request.onerror = handler.onerror

    # Retrieve all items from a given store
    # TODO: allow for order_by and pagination options.
    index: (handler, options) ->
      @open @defaultHandler
      transaction = @datastore.transaction [options.storeName], 'readwrite'
      objStore = transaction.objectStore options.storeName
      keyRange = @IDBKeyRange.lowerBound 0
      cursorRequest = objStore.openCursor keyRange
      items = []

      transaction.oncomplete = (event) ->
        handler.onsuccess items

      cursorRequest.onsuccess = (event) ->
        result = event.target.result
        if not result
          return
        items.push result.value
        result.continue()

      cursorRequest.onerror = handler.onerror

    # Create a new item.
    # :param Object itemObject: the item data.
    create: (itemObject, handler, options) ->
      @open(
        onsuccess: =>
          transaction = @datastore.transaction [options.storeName], 'readwrite'
          objStore = transaction.objectStore options.storeName
          itemObject.id = @guid()
          request = objStore.put itemObject, itemObject.id
          request.onsuccess = ->
            handler.onsuccess itemObject
          request.onerror = handler.onerror
        onerror: handler.onerror
      )

    # Update an existing item
    # Note: error if `key` does not correspond to an existing item.
    update: (key, newObject, handler, options) ->
      @open @defaultHandler
      @open(
        onsuccess: =>
          transaction = @datastore.transaction [options.storeName], 'readwrite'
          objStore = transaction.objectStore options.storeName
          getRequest = objStore.get key
          getRequest.onsuccess = (event) ->
            objectToEnter = _.extend event.target.result, newObject
            putRequest = objStore.put objectToEnter, key
            putRequest.onsuccess = ->
              handler.onsuccess objectToEnter
            putRequest.onerror = ->
              handler.onerror "Update request failed"
          getRequest.onerror = ->
            handler.onerror "There is no #{options.storeName} with key #{key}"
        onerror: handler.onerror
      )

    # Delete an item.
    # :param Object itemObject: the form data.
    delete: (key, handler, options) ->
      @open @defaultHandler
      transaction = @datastore.transaction [options.storeName], 'readwrite'
      objStore = transaction.objectStore options.storeName
      request = objStore.delete key
      request.onsuccess = handler.onsuccess
      request.onerror = handler.onerror

    # Search across forms.
    # TODO: model the query object on the OLD's search API
    search: (query, handler, options) ->
      @open @defaultHandler

    # Delete entire indexedDB database.
    # FIXME: this messes up the indexedDB database in ways I don't understand...
    # WARNING: do not use this!
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


  # An form store-specific interface to a FieldDBIDB instance.
  class FormStore

    # Requires a FieldDBIDB instance
    constructor: (@db) ->

    # Create a new form.
    # :param Object formObject: the form data.
    create: (formObject, handler, options) ->
      options ?= {}
      options.storeName = 'forms'
      @db.create formObject, handler, options

    # Get all forms.
    index: (handler, options) ->
      options ?= {}
      options.storeName = 'forms'
      @db.index handler, options

    # Get a form by id.
    show: (formId, handler, options) ->
      options ?= {}
      options.storeName = 'forms'
      @db.show formId, handler, options

    # Update a form.
    update: (formId, formObject, handler, options) ->
      options ?= {}
      options.storeName = 'forms'
      @db.update formId, formObject, handler, options

    # Delete a form.
    delete: (formId, handler, options) ->
      options ?= {}
      options.storeName = 'forms'
      @db.delete formId, handler, options

    search: (query, handler, options) ->


  # The Object that we export.
  FieldDBIDB: FieldDBIDB
  FormStore: FormStore

