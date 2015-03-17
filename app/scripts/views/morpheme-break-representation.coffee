define ['./representation'], (RepresentationView) ->

  # Morpheme Break Representation View
  # ----------------------------------
  #
  # A view for the representation of a morpheme break field such that the representation
  # consists simply of the field value.

  class ValueRepresentationView extends RepresentationView
    initialize: (@context) ->
      @context.value = @utils.encloseIfNotAlready context.value, '/', '/'

