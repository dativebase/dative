define [
  './field-display'
  './tag'
  './array-of-related-resources-representation-set'
  './related-resource-representation'
  './../models/tag'
  './../collections/tags'
  './../utils/globals'
], (FieldDisplayView, TagView, ArrayOfRelatedResourcesRepresentationSetView,
  RelatedResourceRepresentationView, TagModel, TagsCollection, globals) ->

  # Array of Related Resources Field Display View
  # ---------------------------------------------
  #
  # A view for displaying an array of `RelatedResourceRepresentationView`
  # instances. That is, this is useful when you want to display all of the tags
  # associated to a form such that each tag is a ling that, when clicked, opens
  # up that resource in a dialog view in the page.

  class ArrayOfRelatedResourcesFieldDisplayView extends FieldDisplayView

    resourceName: 'tag'
    attributeName: 'tags'

    relatedResourceRepresentationViewClass: RelatedResourceRepresentationView

    getContext: ->
      _.extend(super,
        subattribute: 'name'
        relatedResourceRepresentationViewClass:
          @relatedResourceRepresentationViewClass
        resourceName: @resourceName
        attributeName: @attributeName
        resourceModelClass: TagModel
        resourcesCollectionClass: TagsCollection
        resourceViewClass: TagView
        resourceAsString: (r) -> r
        getRelatedResourceId: ->
          finder = {}
          finder[@subattribute] = @context.originalValue
          _.findWhere(@context.model.get(@attributeName), finder).id
      )

    getRepresentationView: ->
      new ArrayOfRelatedResourcesRepresentationSetView @context


    # Relational Synchronization stuff
    ############################################################################

    listenToEvents: ->
      @stopAndRelisten()
      @listenTo @model, "change:#{@attributeName}", @refresh
      @listenTo Backbone, 'fieldVisibilityChange', @fieldVisibilityChange

    # TODO: delete all this stuff. It has all now been moved to `ResourceView`,
    # which is where it belongs ...


    listenToEvents_: ->
      super

      # We listen on the global model to see whether our collection has
      # changed. If so, one or more of our related resources may have been
      # deleted or modified.
      @listenTo globals,
        "change:#{@utils.pluralize(@utils.camel2snake(@resourceName))}",
        @checkIfResourceChanged

    # Determine wether the related resources that we are displaying have changed
    # and trigger the appropriate method for the delete case or the update case.
    checkIfResourceChanged: ->
      if @context.value
        try
          relatedResources = @context.model.get @attributeName
          ids = (o.id for o in relatedResources)
          attr = @utils.pluralize @utils.camel2snake(@resourceName)
          resourcesInGlobals = globals.get(attr).data
          relatedResourcesInGlobals =
            _.filter(resourcesInGlobals, (o) -> o.id in ids)
          if relatedResourcesInGlobals.length is relatedResources.length
            @resourcesUpdated relatedResourcesInGlobals
          else
            @deletion relatedResourcesInGlobals

    deletion: (relatedResourcesInGlobals) ->
      @context.model.set @attributeName, relatedResourcesInGlobals

    resourcesUpdated: (relatedResourcesInGlobals) ->
      if _.isEqual relatedResourcesInGlobals, @context.model.get(@attributeName)
        @refresh()
      else
        @context.model.set @attributeName, relatedResourcesInGlobals

