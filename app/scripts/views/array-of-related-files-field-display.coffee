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
  # For displaying the files that are related to another resource. Each file is
  # represented by a link (whose text is the filename or the name) that
  # triggers an opening of the file in a dialog box.

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
        getRelatedResourceId: ->
          finder = {}
          finder[@subattribute] = @context.originalValue
          _.findWhere(@context.model.get(@attributeName), finder).id
      )

    # The string returned by this method will be the text of link that
    # represents each selected file.
    # NOTE: the repetitive logic here is for search match highlighting.
    resourceAsString: (resourceId) ->
      resource = _.findWhere(@model.get(@attributeName), {id: resourceId})
      if resource.filename

        if @context.searchPatternsObject
          try
            regex = @context.searchPatternsObject[@attributeName].filename
          catch
            regex = null
          if regex
            @utils.highlightSearchMatch regex, resource.filename
          else
            resource.filename
        else
          resource.filename

      else if resource.name

        if @context.searchPatternsObject
          try
            regex = @context.searchPatternsObject[@attributeName].name
          catch
            regex = null
          if regex
            @utils.highlightSearchMatch regex, resource.name
          else
            resource.name
        else
          resource.name

      # You can't search on parent_file sub-attributes
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
            @refresh()

