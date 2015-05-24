define [
  './resources'
  './../models/search'
], (ResourcesCollection, SearchModel) ->

  # Searches Collection
  # -----------------------
  #
  # Holds models for searches.

  class SearchesCollection extends ResourcesCollection

    resourceName: 'search'
    model: SearchModel

    serverSideResourceName: 'formsearches'

