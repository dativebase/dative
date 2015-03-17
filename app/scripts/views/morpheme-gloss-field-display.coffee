define [
  './field-display'
  './morpheme-gloss-representation'
], (FieldDisplayView, MorphemeGlossRepresentationView) ->

  # Morpheme Gloss Field Display View
  # ---------------------------------
  #
  # A view for displaying a morpheme gloss field.

  class MorphemeGlossFieldDisplayView extends FieldDisplayView

    getRepresentationView: ->
      new MorphemeGlossRepresentationView @context

