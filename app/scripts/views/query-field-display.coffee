define [
  './field-display'
  './query-representation'
], (FieldDisplayView, QueryRepresentationView) ->

  # Query Field Display View
  # -------------------------
  #
  # A view for displaying a query.

  class QueryFieldDisplayView extends FieldDisplayView

    getRepresentationView: ->
      new QueryRepresentationView @context


