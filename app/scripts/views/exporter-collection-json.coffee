define [
  './exporter'
], (ExporterView) ->

  # Exporter that exports collections of resources as CSV
  # This class defines an interface to the exporter as well as the logic for
  # querying the server and formatting the data for export.

  class ExporterCollectionJSONView extends ExporterView

    title: -> 'JSON (JavaScript Object Notation)'

    description: ->
      'JSON export of a collection of resources'

    # This array should contain 'collection' or 'model' or '*'
    exportTypes: -> ['*']

    export: ->
      console.log 'you want to export as JSON'
      @$(@contentContainerSelector()).slideDown()
      $contentContainer = @$ @contentSelector()
      if @model
        content = "<pre>#{@getModelAsFormattedJSON @model}</pre>"
      else if @collection
        content = "<pre>#{@getCollectionAsFormattedJSON @collection}</pre>"
      else
        content = 'Sorry, unable to generate an export.'
      $contentContainer.html content

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
