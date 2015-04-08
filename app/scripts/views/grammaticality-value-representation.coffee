define [
  './representation'
  './../templates/grammaticality-value-representation'
], (RepresentationView, grammaticalityValueRepresentationTemplate) ->

  # Grammaticality Value Representation View
  # ----------------------------------------
  #
  # A view for the representation of a field such that the representation
  # consists of the field value prefixed by the grammaticality of the form.

  class GrammaticalityValueRepresentationView extends RepresentationView

    template: grammaticalityValueRepresentationTemplate

