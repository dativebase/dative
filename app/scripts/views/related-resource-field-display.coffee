define [
  './resource'
  './field-display'
  './related-resource-representation'
  './../models/resource'
  './../collections/resources'
  './../utils/globals'
], (ResourceView, FieldDisplayView, RelatedResourceRepresentationView,
  ResourceModel, ResourcesCollection, globals) ->

  # Related Resource Field Display View
  # -----------------------------------
  #
  # This is a field display that displays a related resource (e.g., a form's
  # enterer) as a descriptive link that, when clicked retrieves the resource
  # data from the server and causes it to be displayed in a dialog box.

  class RelatedResourceFieldDisplayView extends FieldDisplayView

    # Override these in sub-classes.
    resourceName: 'resource'
    attributeName: 'resource'
    resourceModelClass: ResourceModel
    resourcesCollectionClass: ResourcesCollection
    resourceViewClass: ResourceView
    relatedResourceRepresentationViewClass: RelatedResourceRepresentationView

    # This method should return a string representation of the related resource.
    resourceAsString: (resource) -> resource.name

    # Override this in a subclass to swap in a new representation view.
    getRepresentationView: ->
      new @relatedResourceRepresentationViewClass @context

    getContext: ->
      context = super
      context.resourceAsString = @resourceAsString
      context.resourceName = @resourceName
      context.attributeName = @attributeName
      context.resourceModelClass = @resourceModelClass
      context.resourcesCollectionClass = @resourcesCollectionClass
      context.resourceViewClass = @resourceViewClass
      context.relatedResourceRepresentationViewClass =
        @relatedResourceRepresentationViewClass
      context

    # Return an in-line CSS style to hide the HTML of an empty form attribute
    # Note the use of `=>` so that the ECO template knows to use this view's
    # context.
    shouldBeHidden: ->
      value = @context.value
      if _.isDate(value) or _.isNumber(value) or _.isBoolean(value)
        false
      else if _.isEmpty(value) or @isValueless(value)
        true
      else
        false


    # Relational Synchronization stuff
    ############################################################################

    listenToEvents: ->
      @stopAndRelisten()
      @listenTo @model, "change:#{@attributeName}", @refresh

    # TODO: delete all this stuff. It has all now been moved to `ResourceView`,
    # which is where it belongs ...


    __listenToEvents__: ->
      super

      # We listen on the global model to see whether our collection has
      # changed. If so, our related resource may have been deleted or modified.
      @listenTo globals,
        "change:#{@utils.pluralize(@utils.camel2snake(@resourceName))}",
        @checkIfResourceChanged

    # Determine wether the related resource that we are displaying has changed
    # and trigger the appropriate method for the delete case or the update
    # case.
    checkIfResourceChanged: ->
      if @context.value
        try
          id = @context.model.get(@attributeName).id
          attr = @utils.pluralize @utils.camel2snake(@resourceName)
          collectionArray = globals.get(attr).data
          myResourceObject = _.findWhere collectionArray, {id: id}

          # Note that we refresh this field display if its collection has been
          # updated. This means that a lot of displays will needlessly refresh.
          # I'm fine with this for now.
          if myResourceObject
            @resourceUpdated myResourceObject
          else
            @resourceDeleted()

    resourceDeleted: ->
      @context.model.set @attributeName,
        @context.model.defaults()[@attributeName]

    resourceUpdated: (myResourceObject) ->
      if _.isEqual myResourceObject, @context.model.get(@attributeName)
        @refresh()
      else
        @context.model.set @attributeName, myResourceObject

