define [
  './exporter'
], (ExporterView) ->

  # Exporter that exports collections of resources as CSV
  # This class defines an interface to the exporter as well as the logic for
  # querying the server and formatting the data for export.

  class ExporterCollectionCSVView extends ExporterView

    title: -> 'CSV (comma-separated values)'

    description: ->
      'CSV export of a collection of resources'

    export: ->
      console.log 'you want to export as CSV'

