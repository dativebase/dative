define [
  'backbone'
  './utils'
], (Backbone, utils) ->

  # This module returns a single `Backbone.Model` instance that is passed
  # around in order to store global data. Special-purpose logic allows for
  # arrays of resource objects to be stored and to react to alterations by
  # issuing events that views can listen for.
  #
  # TODOs:
  #
  # - sort options (here or in views?)
  # - add timestamps when modifying `globals`
  # - centralize control of `globals` modification in this module

  class Globals extends Backbone.Model

    # This object will have the names of resources that we are tracking as its
    # attributes. The values will be objects that contain metadata about the
    # resource being tracked. These tracked resources are the resource
    # collections that are needed globally to keep various views in sync. E.g.,
    # when a syntactic category is added or updated we want that change to
    # be reflected in various interfaces that allow users to specify a category
    # for another resource.
    trackedResources: {}

    # Every time we set a set of resources on `globals`, we begin "tracking"
    # changes to that resource collection, if we're not doing so already.
    set: (key, val, options) ->
      if utils.type(key) is 'object'
        @track(key2, val2) for key2, val2 of key
      else
        @track key, val
      super key, val, options

    # If we're not already tracking `resourceName`, then we begin tracking it
    # by listening for update/add/delete events on it.
    track: (resourceName, val) ->
      if resourceName not of @trackedResources
        if val.data.length > 0
          @trackedResources[resourceName] = {attributes: _.keys(val.data[0])}
        else
          @trackedResources[resourceName] = {}

        @listenForResourceChange resourceName

    # Listen for changes on this resource collection. E.g., add, update, or
    # delete events.
    listenForResourceChange: (resourceName) ->

      tmp = utils.capitalize(
        utils.snake2camel(utils.singularize(resourceName)))

      addEvent = "add#{tmp}Success"
      addMethod = (model) =>
        @addResource resourceName, model
      @listenTo Backbone, addEvent, addMethod

      updateEvent = "update#{tmp}Success"
      updateMethod = (model) =>
        @updateResource resourceName, model
      @listenTo Backbone, updateEvent, updateMethod

      deleteEvent = "destroy#{tmp}Success"
      deleteMethod = (model) =>
        @deleteResource resourceName, model
      @listenTo Backbone, deleteEvent, deleteMethod

    # A new resource has been added. `resourceName` is the attribute name for
    # that resource on this `globals` model; e.g., `@get(resourceName)` will
    # return an array of elicitation method objects, if `resourceName` is
    # `"elicitation_methods"`.
    addResource: (resourceName, resourceModel) ->
      resourceObject = @getResourceObjectFromModel resourceName, resourceModel
      @get(resourceName).data.push resourceObject
      @trigger "change:#{resourceName}"

    # An existing resource has been updated.
    updateResource: (resourceName, resourceModel) ->
      resourceObject = @getResourceObjectFromModel resourceName, resourceModel
      resourcesArray = @get(resourceName).data
      storedResourceObject = _.findWhere resourcesArray, {id: resourceObject.id}
      for attr, val of resourceObject
        storedResourceObject[attr] = val
      @trigger "change:#{resourceName}"

    # An existing resource has been deleted.
    deleteResource: (resourceName, resourceModel) ->
      resourcesArray = @get(resourceName).data
      for resourceObject, index in resourcesArray
        try
          if resourceObject.id is resourceModel.get('id')
            resourcesArray.splice index, 1
      @trigger "change:#{resourceName}"

    # Return an object based on the BB model `resourceModel` that only has the
    # attributes that we are tracking.
    getResourceObjectFromModel: (resourceName, resourceModel) ->
      try
        attributes = @trackedResources[resourceName].attributes
      catch
        attributes = []
      resourceObject = {}
      for attribute in attributes
        resourceObject[attribute] = resourceModel.get attribute
      resourceObject

    relatedResources:
      collection: [
        'speakers'
        'users'
        'tags'
        'sources'
        'collection_types'
        'markup_languages'
      ]

      collection_search: [
        'collection_search_parameters'
      ]

      file: [
        'tags'
        'speakers'
        'users'
        'utterance_types'
        'allowed_file_types'
      ]

      file_search: [
        'file_search_parameters'
      ]

      form: [
        'elicitation_methods'
        'grammaticalities'
        'sources'
        'speakers'
        'syntactic_categories'
        'tags'
        'users'
      ]

      form_search: [
        'form_search_parameters'
      ]

      language_search: [
        'language_search_parameters'
      ]

      languageModel: [
        'corpora'
        'morphologies'
        'toolkits'
        # We add these "resources" client-side, cf. `fixToolkits`
        'smoothingAlgorithms'
        'orders'
        'booleans'
      ]

      morphologicalParser: [
        'morpheme_language_models'
        'phonologies'
        'morphologies'
      ]

      morphology: [
        'corpora'
        'script_types'
        'booleans'
      ]

      oldApplicationSettings: [
        'languages'
        'orthographies'
        'users'
      ]

      page: [
        'markup_languages'
      ]

      search: [
        'search_parameters'
        'form_search_parameters'
      ]

      source: [
        'types'
      ]

      speaker: [
        'markup_languages'
      ]

      subcorpus: [
        'form_searches'
        'users'
        'tags'
        'corpus_formats'
      ]

      syntacticCategory: [
        'syntactic_category_types'
      ]

      user: [
        'orthographies'
        'roles'
        'markup_languages'
      ]

  new Globals()

