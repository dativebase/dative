define [
  './array-of-related-resources-field-display'
  './file'
  './../models/file'
], (ArrayOfRelatedResourcesFieldDisplayView, FileView, FileModel) ->

  # Array of Related Files Field Display View
  # -----------------------------------------
  #
  # ...

  class ArrayOfRelatedFilesFieldDisplayView extends ArrayOfRelatedResourcesFieldDisplayView

    getContext: ->
      _.extend(super,
        subattribute: 'id'
        relatedResourceRepresentationViewClass:
          @relatedResourceRepresentationViewClass
        resourceName: 'file'
        attributeName: 'files'
        resourceModelClass: FileModel
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

