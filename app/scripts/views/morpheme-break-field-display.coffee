define [
  './field-display'
  './value-representation'
], (FieldDisplayView, ValueRepresentationView) ->

  # Morpheme Break Field Display View
  # ---------------------------------
  #
  # A view for displaying a morpheme break (or segmentation) field.

  class MorphemeBreakFieldDisplayView extends FieldDisplayView

    getContext: ->
      context = super
      context.value = @utils.encloseIfNotAlready context.value, '/', '/'
      context

