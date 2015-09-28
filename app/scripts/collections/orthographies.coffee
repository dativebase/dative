define [
  './resources'
  './../models/orthography'
], (ResourcesCollection, OrthographyModel) ->

  # Orthographies Collection
  # ------------------------
  #
  # Holds models for orthographies.

  class OrthographiesCollection extends ResourcesCollection

    resourceName: 'orthography'
    model: OrthographyModel




