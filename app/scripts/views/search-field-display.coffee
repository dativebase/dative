define [
  './related-resource-field-display'
  './search'
  './../models/search'
  './../collections/searches'
], (RelatedResourceFieldDisplayView, SearchView, SearchModel,
  SearchesCollection) ->

  # Related Search Field Display View
  # ----------------------------------
  #
  # For displaying a search as a field/attribute of another resource, such that
  # the search is displayed as a link that, when clicked, causes the resource to
  # be displayed in a dialog box.

  class SearchFieldDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'search'
    attributeName: 'search'
    resourceModelClass: SearchModel
    resourcesCollectionClass: SearchesCollection
    resourceViewClass: SearchView
    resourceAsString: (resource) -> resource.name

