define [
  './resource-select-via-search-input'
  './file-as-row'
  './../models/file'
  './../collections/files'
  './../utils/globals'
], (ResourceSelectViaSearchInputView, FileAsRowView, FileModel, FilesCollection,
  globals) ->

  # File Select Via Search Input View
  # ---------------------------------
  #
  # Interface for selecting a file model via a search interface.

  class FileSelectViaSearchInputView extends ResourceSelectViaSearchInputView

    # Change these attributes in subclasses.
    resourceName: 'file'
    resourceModelClass: FileModel
    resourcesCollectionClass: FilesCollection
    resourceAsRowViewClass: FileAsRowView

    # Return a filter expression for searching over file resources that are
    # audio/video and have non-null filename value.
    # TODO: this should not be built-in to the file select via search input
    # because these audio/video restrictions presume that this file is a parent
    # file of another file.
    getIdSearchFilter: (searchTerms) ->
      filter = ['and', [
        @isAudioVideoFilterExpression(),
        @hasAFilenameFilterExpression(),
        [@resourceNameCapitalized, 'id', '=', parseInt(searchTerms[0])]]]

    getAudioVideoMIMETypes: ->
      a = globals.applicationSettings.get 'allowedFileTypes'
      (t for t in a when t[...5] in ['audio', 'video'])

    isAudioVideoFilterExpression: ->
      [
        @resourceNameCapitalized
        'MIME_type'
        'in'
        @getAudioVideoMIMETypes()
      ]

    hasAFilenameFilterExpression: ->
      [
        @resourceNameCapitalized
        'filename'
        '!='
        null
      ]

    getGeneralSearchFilterComplement: ->
      [
        @isAudioVideoFilterExpression()
        @hasAFilenameFilterExpression()
      ]

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

