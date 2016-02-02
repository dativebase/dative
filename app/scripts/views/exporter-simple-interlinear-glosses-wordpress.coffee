define [
  './exporter'
], (ExporterView) ->

  # Exporter that exports individual forms or collections of forms in the
  # format compatible with the Simple Interlinear Glosses (SIG) WordPress
  # plugin. Details available at http://benung.nfshost.com/archives/1721.

  class ExporterSIGPluginView extends ExporterView

    title: -> 'Simple Interlinear Glosses WordPress Plugin Format'

    description: ->
      if @model
        "Simple Interlinear Glosses export of #{@model.resourceName}
          #{@model.id}"
      else if @collection
        if @collection.corpus
          "Simple Interlinear Glosses export of the forms in
            #{@collection.corpus.name}."
        else if @collection.search
          if @collection.search.name
            "Simple Interlinear Glosses export of the
              #{@collection.resourceNamePlural} in search
              #{@collection.search.name}."
          else
            "Simple Interlinear Glosses export of the
              #{@collection.resourceNamePlural} that match the search currently
              being browsed."
        else
          "Simple Interlinear Glosses export of all
            #{@collection.resourceNamePlural} in the database."
      else
        'Simple Interlinear Glosses export of a collection of resources'

    # We export all types of forms: individuals, form search results, the
    # contents of collections, etc.
    exportTypes: -> ['*']

    # We export only forms in SIG format.
    exportResources: -> ['form']

    updateControls: ->
      @clearControls()
      if @model then @selectAllButton()

    export: ->
      @$(@contentContainerSelector()).slideDown()
      $contentContainer = @$ @contentSelector()
      if @model
        content = "<pre>#{@getModelInSIGFormat @model}</pre>"
      else if @collection
        if @collection.corpus
          msg = "fetching a corpus of #{@collection.resourceNamePlural} ..."
        else if @collection.search
          msg = "fetching a search over #{@collection.resourceNamePlural} ..."
        else
          msg = "fetching all #{@collection.resourceNamePlural} ..."
        @fetchResourceCollection true
        content = "<i class='fa fa-fw fa-circle-o-notch fa-spin'></i>#{msg}"
      else
        content = 'Sorry, unable to generate an export.'
      $contentContainer.html content

    # We have retrieved an array of form objects in (`collectionArray`). If it
    # contains more than 100 results we create a link to a file containing the
    # export. Otherwise, we put the export content in the exporter interface
    # along with a "Select All" button.
    fetchResourceCollectionSuccess: (collectionArray) ->
      super
      $contentContainer = @$ @contentSelector()
      if collectionArray.length is 0
        msg = "Sorry, there are no #{@collection.resourceNamePlural} to export"
        $contentContainer.html msg
        return
      sigString = @getCollectionAsSIGString collectionArray
      if collectionArray.length > 100
        mimeType = 'text/plain; charset=utf-8;'
        blob = new Blob [sigString], {type : mimeType}
        url = URL.createObjectURL blob
        if @collection.corpus
          name = "corpus-of-#{@collection.resourceNamePlural}-\
            #{(new Date()).toISOString()}.txt"
        else if @collection.search
          name = "search-over-#{@collection.resourceNamePlural}-\
            #{(new Date()).toISOString()}.txt"
        else
          name = "#{@collection.resourceNamePlural}-\
            #{(new Date()).toISOString()}.txt"
        anchor = "<a href='#{url}'
          class='export-link dative-tooltip'
          type='#{mimeType}'
          title='Click to download your export file'
          download='#{name}'
          target='_blank'
          ><i class='fa fa-fw fa-file-o'></i>#{name}</a>"
        $contentContainer.html anchor
        @$('.export-link.dative-tooltip').tooltip()
      else
        $contentContainer.html "<pre>#{sigString}</pre>"
        @selectAllButton()

    # Return a string representing the export of the `collectionArray` in SIG
    # format.
    getCollectionAsSIGString: (collectionArray) ->
      @errors = false
      tmp = []
      for modelObject in collectionArray
        tmp.push @getModelInSIGFormat(modelObject)
      if @errors then Backbone.trigger 'sigExportError'
      tmp.join '\n\n'

    # If it looks like the translation is enclosed in quotation marks of some
    # kind, leave it be; otherwise, enclose it in single Unicode left and right
    # quotation mark characters.
    quoteTranslation: (translation) ->
      first = translation[0]
      last = translation[translation.length - 1]
      if (first == "'" and last == "'") or
      (first == '"' and last == '"') or
      (first == '\u2018' and last == '\u2019') or
      (first == '\u201C' and last == '\u201D')
        translation
      else
        "\u2018#{translation}\u2019"

    # Return the model object's data in the Simple Interlinear Glosses WordPress
    # format.
    getModelInSIGFormat: (model) ->
      if model instanceof Backbone.Model
        model = model.attributes
      igtVals = []
      igtAttrs = [
        'narrow_phonetic_transcription'
        'phonetic_transcription'
        'transcription'
        'morpheme_break'
        'morpheme_gloss'
      ]
      for attr in igtAttrs
        val = model[attr]
        if val
          if attr == 'transcription'
            igtVals.push "#{model['grammaticality']}#{val}"
          else
            igtVals.push val
      translations = []
      for t in model['translations']
        translations.push "#{t['grammaticality']}#{@quoteTranslation t['transcription']}"
      "[gloss]#{igtVals.join '\n'}[/gloss]\n#{translations.join '\n'}"

