define [
  './resources'
  './collection'
  './search-widget'
  './search-field'
  './../collections/collections'
  './../models/collection'
  './../models/search'
  './../utils/globals'
], (ResourcesView, CollectionView, SearchWidgetView, SearchFieldView,
  CollectionsCollection, CollectionModel, SearchModel, globals) ->


  class CollectionSearchFieldViewNoLabel extends SearchFieldView

    showLabel: false
    targetResourceName: 'collection'


  class CollectionSearchModel extends SearchModel

    # Change the following three attributes if this search model is being used
    # to search over a resource other than forms, e.g., over collection
    # resources.
    targetResourceName: 'collection'
    targetResourcePrimaryAttribute: 'title'
    targetModelClass: CollectionModel


  class CollectionSearchWidgetView extends SearchWidgetView

    targetResourceName: 'collection'
    targetModelClass: CollectionModel
    searchModelClass: CollectionSearchModel
    searchFieldViewClass: CollectionSearchFieldViewNoLabel


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
    searchable: true
    searchView: CollectionSearchWidgetView
    searchModel: CollectionSearchModel

