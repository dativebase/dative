define ['./representation'], (RepresentationView) ->

  # Value Representation View
  # -------------------------
  #
  # A view for the representation of a field such that the representation
  # consists simply of the field value.

  class BooleanIconRepresentationView extends RepresentationView

    valueFormatter: (value) ->
      if value is true
        '<i class="fa fa-check boolean-icon true"></i>'
      else if value is false
        '<i class="fa fa-times boolean-icon false"></i>'
      else
        value

