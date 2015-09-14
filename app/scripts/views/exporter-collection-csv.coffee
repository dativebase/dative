define [
  './exporter'
  './../models/source'
], (ExporterView, SourceModel) ->

  # Exporter that exports a collection of forms as CSV
  #
  # I have strived to adhere to the RFC #4180 spec. See
  # https://tools.ietf.org/html/rfc4180.

  class ExporterCollectionCSVView extends ExporterView

    title: -> 'CSV'

    description: ->
      if @collection
        if @collection.corpus
          "CSV (comma-separated values) export of the forms in
            #{@collection.corpus.name}."
        else if @collection.search
          if @collection.search.name
            "CSV (comma-separated values) export of the
              #{@collection.resourceNamePlural} in search
              #{@collection.search.name}."
          else
            "CSV (comma-separated values) export of the
              #{@collection.resourceNamePlural} that match the search currently
              being browsed."
        else
          "CSV (comma-separated values) export of all
            #{@collection.resourceNamePlural} in the database."
      else
        'CSV (comma-separated values) export of a collection of resources'

    # CSV is only for collections (doesn't really make sense to export a single
    # resource as CSV ...)
    exportTypes: -> ['collection']

    # Right now CSV only works for form resources. Note that there are
    # resource-specific decisions to make for CSV: order of columns, how to
    # stringify/serialize values that are objects/arrays, etc.
    exportResources: -> ['form']

    export: ->
      @$(@contentContainerSelector()).slideDown()
      $contentContainer = @$ @contentSelector()
      if @collection
        if @collection.corpus
          msg = "fetching a corpus of #{@collection.resourceNamePlural} ..."
        else if @collection.search
          msg = "fetching a search over #{@collection.resourceNamePlural} ..."
        else
          msg = "fetching all #{@collection.resourceNamePlural} ..."
        @fetchResourceCollection true # `true` means *do* JSON-parse the return value
        content = "<i class='fa fa-fw fa-circle-o-notch fa-spin'></i>#{msg}"
      else
        content = 'Sorry, unable to generate an export.'
      $contentContainer.html content

    # We have retrieved a string of JSON and have parsed it to a JavaScript
    # array. We convert that array to a string of CSV and create an anchor/link
    # to it that causes the browser to download the file.
    # See http://terminaln00b.ghost.io/excel-just-save-it-as-a-csv-noooooooo/
    fetchResourceCollectionSuccess: (collectionArray) ->
      super
      if collectionArray.length is 0
        msg = "Sorry, there are no #{@collection.resourceNamePlural} to export"
        @$('.exporter-export-content').html msg
        return
      csvString = @getCollectionAsCSVString collectionArray
      mimeType = 'text/csv; header=present; charset=utf-8;'
      blob = new Blob [csvString], {type: mimeType}
      url = URL.createObjectURL blob
      if @collection.corpus
        name = "corpus-of-#{@collection.resourceNamePlural}-\
          #{(new Date()).toISOString()}.csv"
      else if @collection.search
        name = "search-over-#{@collection.resourceNamePlural}-\
          #{(new Date()).toISOString()}.csv"
      else
        name = "#{@collection.resourceNamePlural}-\
          #{(new Date()).toISOString()}.csv"
      anchor = "<a href='#{url}'
        class='export-link dative-tooltip'
        type='#{mimeType}'
        title='Click to download your export file'
        download='#{name}'
        target='_blank'
        ><i class='fa fa-fw fa-file-o'></i>#{name}</a>"
      @$('.exporter-export-content').html anchor
      @$('.export-link.dative-tooltip').tooltip()

    getCollectionAsCSVString: (collectionArray) ->
      @errors = false
      tmp = [@getCSVHeaderString(collectionArray[0])]
      for modelObject in collectionArray
        tmp.push @getModelAsCSVString(modelObject)
      if @errors then Backbone.trigger 'csvExportError'
      tmp.join('\r\n')

    getModelAsCSVString: (modelObject) ->
      tmp = []
      for attr in @configCSV.form.orderedAttributes
        val = modelObject[attr]
        if attr of @configCSV.form.converters
          converter = (x) => @[@configCSV.form.converters[attr]](x)
          val = converter val
        else
          val = @defaultConverter val
        tmp.push val
      tmp.join ','

    getCSVHeaderString: (modelObject) ->
      (@utils.snake2regular(x) \
        for x in @configCSV.form.orderedAttributes).join ','

    # For each resource that this exporter exports, there is an array that
    # defines, in sort order, the attributes whose values will be in the export
    # (`orderedAttributes`), as well as an object (`converters`) that specifies
    # particular converter methods to transform non-string/number values into
    # strings.
    configCSV:
      form:
        orderedAttributes: [
          'grammaticality'
          'transcription'
          'morpheme_break'
          'morpheme_gloss'
          'translations'
          'phonetic_transcription'
          'narrow_phonetic_transcription'
          'comments'
          'speaker_comments'
          'syntax'
          'semantics'
          'status'
          'elicitation_method'
          'syntactic_category'
          'syntactic_category_string'
          'break_gloss_category'
          'speaker'
          'elicitor'
          'enterer'
          'modifier'
          'verifier'
          'source'
          'tags'
          'files'
          'collections'
          'date_elicited'
          'datetime_entered'
          'datetime_modified'
          'UUID'
          'id'
        ]
        converters:
          translations: 'translationsToString'
          syntactic_category: 'objectWithNameToString'
          elicitation_method: 'objectWithNameToString'
          speaker: 'personToString'
          elicitor: 'personToString'
          enterer: 'personToString'
          modifier: 'personToString'
          verifier: 'personToString'
          source: 'sourceToString'
          tags: 'arrayOfObjectsWithNamesToString'
          files: 'arrayOfFilesToString'
          collections: 'arrayOfObjectsWithTitlesToString'

    ############################################################################
    # Converters
    ############################################################################

    sourceToString: (object) ->
      if not object then return ''
      try
        (new SourceModel(object)).getAuthorEditorYearDefaults()
      catch
        console.log "Error when stringify-ing a source for CSV export"
        ''

    personToString: (object) ->
      if not object then return ''
      try
        firstName = object.first_name or ''
        lastName = object.last_name or ''
        if firstName and lastName
          @defaultConverter "#{firstName} #{lastName}"
        else
          ''
      catch
        console.log "Error when stringify-ing a person for CSV export"
        ''

    objectWithNameToString: (object) ->
      if not object then return ''
      try
        if object.name then @defaultConverter(object.name) else ''
      catch
        console.log "Error when stringify-ing an object with a name for CSV
          export"
        ''

    # An array of objects that all have a unique defining attribute, e.g.,
    # name. Return a string that is all of those defining attribute values,
    # delimited by commas.
    arrayOfObjectsWithSingleDefiningAttrToString: (array, attr='name') ->
      if not array then return ''
      tmp = []
      for o in array
        try
          if o[attr] then tmp.push o[attr]
      if tmp.length > 0
        @defaultConverter tmp.join(', ')
      else
        ''

    arrayOfObjectsWithTitlesToString: (array) ->
      @arrayOfObjectsWithSingleDefiningAttrToString array, 'title'

    # Here we represent an array of tags by delimiting the tag names with
    # commas. This may be problematic/confusing since tag names may contain
    # commas ...
    arrayOfObjectsWithNamesToString: (array) ->
      @arrayOfObjectsWithSingleDefiningAttrToString array

    arrayOfFilesToString: (array) ->
      if not array then return ''
      tmp = []
      for f in array
        try
          if f.name
            tmp.push f.name
          else if f.filename
            tmp.push f.filename
          else if f.id
            tmp.push "file #{f.id}"
      if tmp.length > 0
        @defaultConverter tmp.join(', ')
      else
        ''

    translationsToString: (translations) ->
      if not translations then return ''
      tmp = []
      for tl in translations
        if tl.grammaticality
          grammaticality = "#{tl.grammaticality} "
        else
          grammaticality = ''
        tmp.push "#{grammaticality}#{tl.transcription}"
      @defaultConverter tmp.join('; ')

    defaultConverter: (value) ->
      try
        @_defaultConverter value
      catch
        @errors = true
        'ERROR'

    _defaultConverter: (value) ->
      if value in [null, undefined]
        ''
      else
        # If a value contains CSV reserved characters (CRLF, double quote or
        # comma), then the entire field should be enclosed in double quotes.
        if /\r\n|"|,/.test value
          prefix = suffix = '"'
        else
          prefix = suffix = ''
        # Double quotes inside a value need to be escaped with another double
        # quote.
        "#{prefix}#{String(value).replace(/"/g, '""')}#{suffix}"

    # NOTE: don't use this! Without this the output seems to already be
    # correctly UTF-8-encoded! ...
    # Encode string as UTF-8. NOTE: not sure if this is necessary, but I think
    # it is because I think JS strings are UTF-16 encoded by default ...
    # See:
    # - http://ecmanaut.blogspot.ca/2006/07/encoding-decoding-utf8-in-javascript.html
    # - http://monsur.hossa.in/2012/07/20/utf-8-in-javascript.html
    encodeUTF8: (s) -> unescape encodeURIComponent(s)

