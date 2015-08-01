define [
  './resources'
  './collection'
  './../collections/collections'
  './../models/collection'
  './../utils/globals'
], (ResourcesView, CollectionView, CollectionsCollection,
  CollectionModel, globals) ->

  # Collections View
  # ----------------
  #
  # Displays a collection of (OLD) collections (i.e., texts) for browsing, with
  # pagination. Also contains a model-less `CollectionView` instance for
  # creating new collections within the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class CollectionsView extends ResourcesView

    resourceName: 'collection'
    resourceView: CollectionView
    resourcesCollection: CollectionsCollection
    resourceModel: CollectionModel



