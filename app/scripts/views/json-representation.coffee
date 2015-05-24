define ['./representation'], (RepresentationView) ->

  # JSON Representation View
  # -------------------------
  #
  # A view for the representation of a field whose value is a JSON object.

  class JSONRepresentationView extends RepresentationView

    valueFormatter: (value) -> JSON.stringify value, undefined, 2

