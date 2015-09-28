define [
  './resource-select-via-search-input'
  './morphology-as-row'
  './../models/morphology'
  './../collections/morphologies'
], (ResourceSelectViaSearchInputView, MorphologyAsRowView, MorphologyModel,
  MorphologiesCollection) ->

  class MorphologySelectViaSearchInputView extends ResourceSelectViaSearchInputView

    # Change these attributes in subclasses.
    resourceName: 'morphology'
    resourceModelClass: MorphologyModel
    resourcesCollectionClass: MorphologiesCollection
    resourceAsRowViewClass: MorphologyAsRowView

    resourceAsString: (resource) -> resource.name

    # These are the `[<attribute]`s or `[<attribute>, <subattribute>]`s that we
    # "smartly" search over.
    smartStringSearchableFileAttributes: [
      ['id']
      ['name']
      ['description']
      ['lexicon_corpus', 'name']
      ['rules_corpus', 'name']
    ]

