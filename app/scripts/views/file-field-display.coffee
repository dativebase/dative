define [
  './file'
  './related-resource-field-display'
  './../models/file'
  './../collections/files'
], (FileView, RelatedResourceFieldDisplayView, FileModel, FilesCollection) ->

  class FileFieldDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'file'
    attributeName: 'file'
    resourceModelClass: FileModel
    resourcesCollectionClass: FilesCollection
    resourceViewClass: FileView

    resourceAsString: (resource) ->
      try
        if resource.name
          resource.name
        else if resource.filename
          resource.filename
        else
          "File #{resource.id}"
      catch
        ''

