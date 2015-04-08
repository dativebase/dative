define ['./representation'], (RepresentationView) ->

  # Morpheme Gloss Representation View
  # ----------------------------------
  #
  # A view for the representation of a morpheme gloss field.

  class MorphemeGlossRepresentationView extends RepresentationView
    valueFormatter: (value) =>
      try
        @utils.smallCapsAcronyms value
      catch
        value

