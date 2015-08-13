define [
  './resource-select-via-search-input'
  './subcorpus-as-row'
  './../models/subcorpus'
  './../collections/subcorpora'
], (ResourceSelectViaSearchInputView, SubcorpusAsRowView, SubcorpusModel,
  SubcorporaCollection) ->

  class SubcorpusSelectViaSearchInputView extends ResourceSelectViaSearchInputView

    # Change these attributes in subclasses.
    resourceName: 'subcorpus'
    resourceModelClass: SubcorpusModel
    resourcesCollectionClass: SubcorporaCollection
    resourceAsRowViewClass: SubcorpusAsRowView

    resourceAsString: (resource) -> resource.name

    # These are the `[<attribute]`s or `[<attribute>, <subattribute>]`s that we
    # "smartly" search over.
    smartStringSearchableFileAttributes: [
      ['id']
      ['name']
      ['description']
      ['content']
      ['tags', 'name']
      ['form_search', 'name']
    ]

    getServerSideResourceNameCapitalized: (resourceNameCapitalized) ->
      'Corpus'

