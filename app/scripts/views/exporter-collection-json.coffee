define [
  './exporter'
], (ExporterView) ->

  # Exporter that exports collections of resources as CSV
  # This class defines an interface to the exporter as well as the logic for
  # querying the server and formatting the data for export.

  class ExporterCollectionJSONView extends ExporterView

    title: -> 'JSON'

    description: ->
      if @model
        "JSON (JavaScript Object Notation) export of #{@model.resourceName}
          #{@model.id}"
      else if @collection
        if @collection.corpus
          "JSON (JavaScript Object Notation) export of the forms in
            #{@collection.corpus.name}."
        else if @collection.search
          if @collection.search.name
            "JSON (JavaScript Object Notation) export of the
              #{@collection.resourceNamePlural} in search
              #{@collection.search.name}."
          else
            "JSON (JavaScript Object Notation) export of the
              #{@collection.resourceNamePlural} that match the search currently
              being browsed."
        else
          "JSON (JavaScript Object Notation) export of all
            #{@collection.resourceNamePlural} in the database."
      else
        'JSON (JavaScript Object Notation) export of a collection of resources'

    # This array should contain 'collection' or 'model' or '*'
    exportTypes: -> ['*']

    listenToEvents: ->
      super

    updateControls: ->
      if @model
        @selectAllButton()
      else
        @removeSelectAllButton()

    export: ->
      @$(@contentContainerSelector()).slideDown()
      $contentContainer = @$ @contentSelector()
      if @model
        content = "<pre>#{@getModelAsFormattedJSON @model}</pre>"
      else if @collection
        if @collection.corpus
          msg = "fetching a corpus of #{@collection.resourceNamePlural} ..."
        else if @collection.search
          msg = "fetching a search over #{@collection.resourceNamePlural} ..."
        else
          msg = "fetching all #{@collection.resourceNamePlural} ..."
        @fetchResourceCollection()
        content = "<i class='fa fa-fw fa-circle-o-notch fa-spin'></i>#{msg}"
      else
        content = 'Sorry, unable to generate an export.'
      $contentContainer.html content

    # We have retrieved a string of JSON (`collectionJSONString`) so we simply
    # create an anchor/link to it that causes the browser to download the file.
    fetchResourceCollectionSuccess: (collectionJSONString) ->
      super
      blob = new Blob [collectionJSONString], {type : 'application/json'}
      url = URL.createObjectURL blob
      if @collection.corpus
        name = "corpus-of-#{@collection.resourceNamePlural}-#{(new Date()).toISOString()}.json"
      else if @collection.search
        name = "search-over-#{@collection.resourceNamePlural}-#{(new Date()).toISOString()}.json"
      else
        name = "#{@collection.resourceNamePlural}-#{(new Date()).toISOString()}.json"
      anchor = "<a href='#{url}'
        class='export-link dative-tooltip'
        type='application/json'
        title='Click to download your export file'
        download='#{name}'
        target='_blank'
        ><i class='fa fa-fw fa-file-o'></i>#{name}</a>"
      @$('.exporter-export-content').html anchor
      @$('.export-link.dative-tooltip').tooltip()

    getModelAsFormattedJSON: (model) ->
      modelObject = @model.toJSON()
      delete modelObject.collection
      JSON.stringify modelObject, undefined, 4

    getCollectionAsFormattedJSON: (collection) ->
      collectionArray = @collection.toJSON()
      modelArray = []
      for modelObject in collectionArray
        delete modelObject.collection
        modelArray.push modelObject
      JSON.stringify modelArray, undefined, 4

