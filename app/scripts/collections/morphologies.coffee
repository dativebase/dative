define [
  './resources'
  './../models/morphology'
], (ResourcesCollection, morphologyModel) ->

  # Morphologies Collection
  # -----------------------
  #
  # Holds models for morphologies.

  class MorphologiesCollection extends ResourcesCollection

    resourceName: 'morphology'
    model: morphologyModel

