define [
  './file'
  './related-resource-field-display'
  './../models/file'
], (FileView, RelatedResourceFieldDisplayView, FileModel) ->


  class MyFileFieldDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'file'
    attributeName: 'parent_file'
    resourceModelClass: FileModel
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


  # File With Parent File Link View
  # -------------------------------
  #
  # A view for displaying individual files, where the parent file value is a
  # link that, when clicked, causes another FileView to be rendered for the
  # parent file. This class is needed so that regular files can link to parent
  # files without circularity.

  class FileWithParentFileLinkView extends FileView

    initialize: (options) ->
      super options
      @attribute2displayView.parent_file = MyFileFieldDisplayView

