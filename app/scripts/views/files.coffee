define [
  './resources'
  './file'
  './../collections/files'
  './../models/file'
], (ResourcesView, FileView, FilesCollection, FileModel) ->

  # Files View
  # -----------------
  #
  # Displays a collection of files for browsing, with pagination. Also
  # contains a model-less FileView instance for creating new files
  # within the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class FilesView extends ResourcesView

    resourceName: 'file'
    resourceView: FileView
    resourcesCollection: FilesCollection
    resourceModel: FileModel

