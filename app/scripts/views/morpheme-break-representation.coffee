define ['./representation'], (RepresentationView) ->

  # Morpheme Break Representation View
  # ----------------------------------
  #
  # A view for the representation of a morpheme break field.

  class MorphemeBreakRepresentationView extends RepresentationView
    valueFormatter: (value) =>
      try
        @utils.encloseIfNotAlready value, '/', '/'
      catch
        value

