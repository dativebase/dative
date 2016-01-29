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

    # When an OLD collection resource is added/updated and its contents contain
    # bad form references, the attribute will be "forms", though from Dative's
    # perspective it should be "contents".
    errorAttributeTransformer: (errorAttribute) ->
      if errorAttribute == 'forms'
        return 'contents'
      errorAttribute

