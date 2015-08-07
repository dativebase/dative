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
        subattribute: 'filename'
        relatedResourceRepresentationViewClass:
          @relatedResourceRepresentationViewClass
        resourceName: 'file'
        attributeName: 'files'
        resourceModelClass: FileModel
        resourceViewClass: FileView
        resourceAsString: (r) -> r
        getRelatedResourceId: ->
          finder = {}
          finder[@subattribute] = @context.originalValue
          _.findWhere(@context.model.get(@attributeName), finder).id
      )

