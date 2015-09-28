define [
  './resources'
  './../models/source'
], (ResourcesCollection, SourceModel) ->

  # Sources Collection
  # ------------------
  #
  # Holds models for sources, i.e., texts referenced by data points.

  class SourcesCollection extends ResourcesCollection

    resourceName: 'source'
    model: SourceModel

