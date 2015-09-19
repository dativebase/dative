define ['./representation'], (RepresentationView) ->

  # Morpheme Gloss Representation View
  # ----------------------------------
  #
  # A view for the representation of a morpheme gloss field.

  class MorphemeGlossRepresentationView extends RepresentationView

    # NOTE: I'm not using this `valueFormatter` method for now because the
    # `smallCapsAronyms` converts the text of the morpheme gloss to lowercase
    # and this wrecks the behaviour of the `interlinearize` method defined in
    # form-base.coffee.
    valueFormatter_: (value) =>
      try
        @utils.smallCapsAcronyms value
      catch
        value

