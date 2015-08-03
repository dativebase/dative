define [
  './resources'
  './file-with-parent-file-link'
  './search-widget'
  './search-field'
  './../collections/files'
  './../models/file'
  './../models/search'
], (ResourcesView, FileWithParentFileLinkView, SearchWidgetView,
  SearchFieldView, FilesCollection, FileModel, SearchModel) ->


  class FileSearchFieldViewNoLabel extends SearchFieldView

    showLabel: false
    targetResourceName: 'file'


  class FileSearchModel extends SearchModel

    # Change the following three attributes if this search model is being used
    # to search over a resource other than forms, e.g., over file resources.
    targetResourceName: 'file'
    targetResourcePrimaryAttribute: 'filename'
    targetModelClass: FileModel


  class FileSearchWidgetView extends SearchWidgetView

    targetResourceName: 'file'
    targetModelClass: FileModel
    searchModelClass: FileSearchModel
    searchFieldViewClass: FileSearchFieldViewNoLabel


  # Files View
  # -----------------
  #
  # Displays a collection of files for browsing, with pagination. Also
  # contains a model-less `FileWithParentFileLinkView` instance for creating new
  # files within the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class FilesView extends ResourcesView

    resourceName: 'file'
    resourceView: FileWithParentFileLinkView
    resourcesCollection: FilesCollection
    resourceModel: FileModel
    searchable: true
    searchView: FileSearchWidgetView
    searchModel: FileSearchModel

