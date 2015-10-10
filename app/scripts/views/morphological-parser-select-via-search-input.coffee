define [
  './resource-select-via-search-input'
  './morphological-parser-as-row'
  './../models/morphological-parser'
  './../collections/morphological-parsers'
], (ResourceSelectViaSearchInputView, MorphologicalParserAsRowView, MorphologicalParserModel,
  MorphologicalParsersCollection) ->

  class MorphologicalParserSelectViaSearchInputView extends ResourceSelectViaSearchInputView

    # Change these attributes in subclasses.
    resourceName: 'morphologicalParser'
    resourceModelClass: MorphologicalParserModel
    resourcesCollectionClass: MorphologicalParsersCollection
    resourceAsRowViewClass: MorphologicalParserAsRowView

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


