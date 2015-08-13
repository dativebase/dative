define [
  './resource-select-via-search-input'
  './file-as-row'
  './../models/file'
  './../collections/files'
], (ResourceSelectViaSearchInputView, FileAsRowView, FileModel,
  FilesCollection) ->

  # File Select Via Search Input View
  # ---------------------------------
  #
  # Interface for selecting a file model via a search interface.

  class FileSelectViaSearchInputView extends ResourceSelectViaSearchInputView

    # The string returned by this method will be the text of link that
    # represents the selected file.
    resourceAsString: (resource) ->
      if resource.filename
        resource.filename
      else if resource.name
        resource.name
      else if resource.parent_file
        resource.parent_file.filename
      else
        "File #{resource.id}"

    # Change these attributes in subclasses.
    resourceName: 'file'
    resourceModelClass: FileModel
    resourcesCollectionClass: FilesCollection
    resourceAsRowViewClass: FileAsRowView


    setSelectedToModel: (resourceAsRowView) ->
      @model.set @context.attribute, resourceAsRowView.model.attributes

    # These are the `[<attribute]`s or `[<attribute>, <subattribute>]`s that we
    # "smartly" search over.
    # TODO: consider fixing the following. You can't search files based on the
    # translations of the forms that they are associated to. This is a failing
    # of the OLD web service search interface. Adding this extra level of depth
    # would be useful here and elsewhere ...
    smartStringSearchableFileAttributes: [
      ['id']
      ['filename']
      ['MIME_type']
      ['name']
      ['url']
      ['description']
      ['forms', 'transcription']
      ['tags', 'name']
    ]

