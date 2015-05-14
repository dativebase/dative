define [
  './field-display'
  './boolean-icon-representation'
], (FieldDisplayView, BooleanIconRepresentationView) ->

  # Boolean Icon Field Display View
  # -------------------------------
  #
  # A view for displaying boolean values (true or false) as icons, e.g., a
  # check or a times ("X").

  class BooleanIconFieldDisplayView extends FieldDisplayView

    getRepresentationView: ->
      new BooleanIconRepresentationView @context

