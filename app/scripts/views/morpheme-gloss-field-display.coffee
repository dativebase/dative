define [
  './field-display'
  './value-representation'
], (FieldDisplayView, ValueRepresentationView) ->

  # Morpheme Gloss Field Display View
  # ---------------------------------
  #
  # A view for displaying a morpheme gloss field.

  class MorphemeGlossFieldDisplayView extends FieldDisplayView

    getContext: ->
      context = super
      context.value = @utils.smallCapsAcronyms context.value
      context


