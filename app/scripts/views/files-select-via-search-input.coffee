define [
  './resources-select-via-search-input'
  './file-as-row'
  './../models/file'
], (ResourcesSelectViaSearchInputView, FileAsRowView, FileModel) ->


  # Files Select Via Search Input View
  # ----------------------------------
  #
  # Interface for selecting *zero or more* file models via a search interface.

  class FilesSelectViaSearchInputView extends ResourcesSelectViaSearchInputView

    # The string returned by this method will be the text of link that
    # represents each selected file.
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
    resourceAsRowViewClass: FileAsRowView

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

