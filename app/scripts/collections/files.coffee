define [
  './resources'
  './../models/file'
], (ResourcesCollection, FileModel) ->

  # Files Collection
  # -----------------------
  #
  # Holds models for files.

  class FilesCollection extends ResourcesCollection

    resourceName: 'file'
    model: FileModel

