define [
  './array-of-related-resources-field-display'
  './file'
  './../models/file'
  './../collections/files'
], (ArrayOfRelatedResourcesFieldDisplayView, FileView, FileModel,
  FilesCollection) ->

  # Array of Related Files Field Display View
  # -----------------------------------------
  #
  # ...

  class ArrayOfRelatedFilesFieldDisplayView extends ArrayOfRelatedResourcesFieldDisplayView

    resourceName: 'file'
    attributeName: 'files'

    getContext: ->
      _.extend(super,
        subattribute: 'id'
        relatedResourceRepresentationViewClass:
          @relatedResourceRepresentationViewClass
        resourceName: @resourceName
        attributeName: @attributeName
        resourceModelClass: FileModel
        resourcesCollectionClass: FilesCollection
        resourceViewClass: FileView
        resourceAsString: @resourceAsString
        #resourceAsString: (r) -> r
        getRelatedResourceId: ->
          finder = {}
          finder[@subattribute] = @context.originalValue
          _.findWhere(@context.model.get(@attributeName), finder).id
      )

    # The string returned by this method will be the text of link that
    # represents each selected file.
    resourceAsString: (resourceId) ->
      resource = _.findWhere(@model.get(@attributeName), {id: resourceId})
      if resource.filename
        resource.filename
      else if resource.name
        resource.name
      else if resource.parent_file
        resource.parent_file.filename
      else
        "File #{resource.id}"


    # Relational Synchronization stuff
    ############################################################################
    #
    # Here we override the default logic related to relational sync that is
    # defined in the base class `ArrayOfRelatedResourcesFieldDisplayView`.
    #
    # Dative does not store arrays of *file* objects in `globals` (in part,
    # because the files resource collection is expected to grow rather large.)
    # Therefore, we need to refine what we listen for in order to stay in sync
    # with the global state (at least from the client-side POV).
    #
    #
    # TODO: delete this because the parent class `ResourceView` now takes care
    # of updating the model in response to these events.  #

    listenToEvents_: ->
      super

      @listenTo Backbone,
        "destroy#{@utils.capitalize @resourceName}Success",
        @checkIfDeleted
      @listenTo Backbone,
        "update#{@utils.capitalize @resourceName}Success",
        @checkIfUpdated

    checkIfDeleted: (deletedModel) ->
      if @context.value
        try
          relatedResources = @context.model.get @attributeName
          ids = (o.id for o in relatedResources)
          if deletedModel.get('id') in ids
            newRelatedResources = (r for r in relatedResources \
              when r.id isnt deletedModel.get('id'))
            @context.model.set @attributeName, newRelatedResources

    checkIfUpdated: (updatedModel) ->
      if @context.value
        try
          relatedResources = @context.model.get @attributeName
          ids = (o.id for o in relatedResources)
          if updatedModel.get('id') in ids
            console.log 'refresh cuz i update'
            @refresh()

