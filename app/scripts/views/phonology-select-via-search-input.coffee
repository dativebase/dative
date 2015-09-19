define [
  './resource-select-via-search-input'
  './phonology-as-row'
  './../models/phonology'
  './../collections/phonologies'
], (ResourceSelectViaSearchInputView, PhonologyAsRowView, PhonologyModel,
  PhonologiesCollection) ->

  class PhonologySelectViaSearchInputView extends ResourceSelectViaSearchInputView

    # Change these attributes in subclasses.
    resourceName: 'phonology'
    resourceModelClass: PhonologyModel
    resourcesCollectionClass: PhonologiesCollection
    resourceAsRowViewClass: PhonologyAsRowView

    resourceAsString: (resource) -> resource.name

    # These are the `[<attribute]`s or `[<attribute>, <subattribute>]`s that we
    # "smartly" search over.
    smartStringSearchableFileAttributes: [
      ['id']
      ['name']
      ['description']
      ['script']
    ]

