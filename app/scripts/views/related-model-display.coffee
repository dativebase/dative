define [
  './field-display'
  './related-model-representation'
], (FieldDisplayView, RelatedModelRepresentationView) ->

  class RelatedModelDisplayView extends FieldDisplayView

    getRepresentationView: ->
      new RelatedModelRepresentationView @context

