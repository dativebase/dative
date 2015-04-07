define [
  './resources'
  './../models/morphology'
], (ResourcesCollection, MorphologyModel) ->

  # Morphologies Collection
  # -----------------------
  #
  # Holds models for morphologies.

  class MorphologiesCollection extends ResourcesCollection

    resourceName: 'morphology'
    model: MorphologyModel

