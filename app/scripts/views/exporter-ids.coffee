define [
  './exporter'
], (ExporterView) ->

  # Exporter that exports collections of resources as lists of ids. This is
  # useful for being able to quickly get all references to a collection. For
  # example, you could use this exporter to get all of the id values of a
  # search so that you could freeze those results in a collection or in a
  # corpus.

  class ExporterIdsView extends ExporterView

    title: -> 'Ids'

    description: ->
      if @collection
        if @collection.corpus
          "Id values of the forms in corpus “#{@collection.corpus.name}.”"
        else if @collection.search
          if @collection.search.name
            "Id values of the #{@collection.resourceNamePlural} in search
              “#{@collection.search.name}.”"
          else
            "Id values of the #{@collection.resourceNamePlural} that match the
            search currently being browsed."
        else
          "Id values of all #{@collection.resourceNamePlural} in the database."
      else
        'Id values of a collection of resources'

    # This array should contain 'collection' or 'model' or '*'
    exportTypes: -> ['collection']

    exportResources: -> ['form']

    updateControls: ->
      @clearControls()
      @selectAllButton()

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
        @fetchResourceCollection true
        content = "<i class='fa fa-fw fa-circle-o-notch fa-spin'></i>#{msg}"
      else
        content = 'Sorry, unable to generate an export.'
      $contentContainer.html content

    # We have retrieved an array of form objects in (`collectionArray`). We
    # convert this to a string of resource id values and put this string in the
    # exporter interface along with a "Select All" button.
    fetchResourceCollectionSuccess: (collectionArray) ->
      super
      $contentContainer = @$ @contentSelector()
      if collectionArray.length is 0
        msg = "Sorry, there are no #{@collection.resourceNamePlural} to export"
        $contentContainer.html msg
        return
      idString = @getCollectionAsIdString collectionArray
      $contentContainer.html "<pre>#{idString}</pre>"
      @selectAllButton()

    # Return a string representing the export of the `collectionArray` as a
    # string of id references.
    getCollectionAsIdString: (collectionArray) ->
      result = []
      for model in collectionArray
        if model instanceof Backbone.Model
          model = model.attributes
        result.push model.id
      result.join ', '

