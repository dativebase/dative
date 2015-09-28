define [
  './resource-select-via-search-input'
  './language-model-as-row'
  './../models/language-model'
  './../collections/language-models'
], (ResourceSelectViaSearchInputView, LanguageModelAsRowView, LanguageModelModel,
  LanguageModelsCollection) ->

  class LanguageModelSelectViaSearchInputView extends ResourceSelectViaSearchInputView

    # Change these attributes in subclasses.
    resourceName: 'languageModel'
    resourceModelClass: LanguageModelModel
    resourcesCollectionClass: LanguageModelsCollection
    resourceAsRowViewClass: LanguageModelAsRowView

    resourceAsString: (resource) -> resource.name

    # These are the `[<attribute]`s or `[<attribute>, <subattribute>]`s that we
    # "smartly" search over.
    smartStringSearchableFileAttributes: [
      ['id']
      ['name']
      ['description']
      ['corpus', 'name']
      ['vocabulary_morphology', 'name']
      ['smoothing']
      ['order']
    ]

    getServerSideResourceNameCapitalized: (resourceNameCapitalized) ->
      'MorphemeLanguageModel'

