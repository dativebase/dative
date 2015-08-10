define [
  './resource-select-via-search-input'
  './resource-as-row'
  './../models/file'
  './../utils/globals'
], (ResourceSelectViaSearchInputView, ResourceAsRowView, FileModel,
  globals) ->


  # File as Row View
  # ----------------
  #
  # A view for displaying a file model as a row of cells, one cell per attribute.
#
  class FileAsRowView extends ResourceAsRowView

    resourceName: 'file'

    orderedAttributes: [
      'id'
      'filename'
      'MIME_type'
      'size'
      'enterer'
      'tags'
      'forms'
    ]

    # Return a string representation for a given `attribute`/`value` pair of
    # this file.
    scalarTransform: (attribute, value) ->
      if @isHeaderRow
        @scalarTransformHeaderRow attribute, value
      else if value
        if attribute in ['elicitor', 'enterer', 'modifier', 'verifier', 'speaker']
          "#{value.first_name} #{value.last_name}"
        else if attribute is 'size'
          @utils.humanFileSize value, true
        else if attribute is 'forms'
          if value.length
            (f.transcription for f in value).join '; '
          else
            ''
        else if attribute is 'tags'
          if value.length
            (t.name for t in value).join ', '
          else
            ''
        else if @utils.type(value) in ['string', 'number']
          value
        else
          JSON.stringify value
      else
        JSON.stringify value


  # File Select Via Search Input View
  # ---------------------------------
  #
  # Interface for selecting a file model via a search interface.

  class FileSelectViaSearchInputView extends ResourceSelectViaSearchInputView

    # Change these attributes in subclasses.
    resourceName: 'file'
    resourceModelClass: FileModel
    resourceAsRowViewClass: FileAsRowView

    # Return a filter expression for searching over file resources that are
    # audio/video and have non-null filename value.
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

