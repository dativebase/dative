define [
  './resource-select-via-search-input'
  './search-as-row'
  './../models/search'
  './../collections/searches'
], (ResourceSelectViaSearchInputView, SearchAsRowView, SearchModel,
  SearchesCollection) ->

  class SearchSelectViaSearchInputView extends ResourceSelectViaSearchInputView

    # Change these attributes in subclasses.
    resourceName: 'search'
    resourceModelClass: SearchModel
    resourcesCollectionClass: SearchesCollection
    resourceAsRowViewClass: SearchAsRowView

    resourceAsString: (resource) -> resource.name

    # These are the `[<attribute]`s or `[<attribute>, <subattribute>]`s that we
    # "smartly" search over.
    smartStringSearchableFileAttributes: [
      ['id']
      ['name']
      ['description']
    ]

    # Override this in sub-classes as necessary, e.g., in a search interface
    # for form searches where 'Search' is wrong and 'FormSearch' is correct.
    getServerSideResourceNameCapitalized: (resourceNameCapitalized) ->
      'FormSearch'

