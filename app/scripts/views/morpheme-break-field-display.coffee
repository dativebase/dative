define [
  './field-display'
  './morpheme-break-representation'
], (FieldDisplayView, MorphemeBreakRepresentationView) ->

  # Morpheme Break Field Display View
  # ---------------------------------
  #
  # A view for displaying a morpheme break (or segmentation) field.

  class MorphemeBreakFieldDisplayView extends FieldDisplayView

    getRepresentationView: ->
      new MorphemeBreakRepresentationView @context

