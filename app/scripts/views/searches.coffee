define [
  './resources'
  './search'
  './../collections/searches'
  './../models/search'
], (ResourcesView, SearchView, SearchesCollection, SearchModel) ->

  # Searches View
  # -----------------
  #
  # Displays a collection of searches for browsing, with pagination. Also
  # contains a model-less SearchView instance for creating new searches
  # within the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class SearchesView extends ResourcesView

    resourceName: 'search'
    resourceView: SearchView
    resourcesCollection: SearchesCollection
    resourceModel: SearchModel


