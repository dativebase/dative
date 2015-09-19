define [
  './resources'
  './../models/collection'
], (ResourcesCollection, CollectionModel) ->

  # Collections Collection
  # ----------------------
  #
  # Holds models for (OLD) collections, i.e., texts.

  class CollectionsCollection extends ResourcesCollection

    resourceName: 'collection'
    model: CollectionModel




