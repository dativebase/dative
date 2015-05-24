define [
  './field-display'
  './json-representation'
], (FieldDisplayView, JSONRepresentationView) ->

  # JSON Field Display View
  # -------------------------
  #
  # A view for displaying a JSON expression.

  class JSONFieldDisplayView extends FieldDisplayView

    getRepresentationView: ->
      new JSONRepresentationView @context

