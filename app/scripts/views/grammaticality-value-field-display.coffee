define [
  './field-display'
  './grammaticality-value-representation'
], (FieldDisplayView, GrammaticalityValueRepresentationView) ->

  # Grammaticality Value Field Display View
  # ---------------------------------------
  #
  # A view for displaying the value of a particular field (e.g., transcription) as
  # well as the grammaticality of the form.
  #
  # This is a useful generalization because one can imagine users wanting the
  # grammaticality represented on various fields.

  class GrammaticalityValueFieldDisplayView extends FieldDisplayView

    getContext: ->
      @grammaticalityAttribute = 'grammaticality'
      _.extend super,
        grammaticalityAttribute: @grammaticalityAttribute
        grammaticalityClass: @getClass @grammaticalityAttribute
        grammaticalityValue: @getValue @grammaticalityAttribute

    getRepresentationView: ->
      new GrammaticalityValueRepresentationView @context

    governedAttributes: -> [@grammaticalityAttribute, @attribute]

