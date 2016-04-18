define [
  './resource-select-via-search-input'
  './keyboard-as-row'
  './../models/keyboard'
  './../collections/keyboards'
], (ResourceSelectViaSearchInputView, KeyboardAsRowView, KeyboardModel,
  KeyboardsCollection) ->

  class KeyboardSelectViaSearchInputView extends ResourceSelectViaSearchInputView

    # Change these attributes in subclasses.
    resourceName: 'keyboard'
    resourceModelClass: KeyboardModel
    resourcesCollectionClass: KeyboardsCollection
    resourceAsRowViewClass: KeyboardAsRowView

    resourceAsString: (resource) -> resource.name

    # These are the `[<attribute]`s or `[<attribute>, <subattribute>]`s that we
    # "smartly" search over.
    smartStringSearchableFileAttributes: [
      ['id']
      ['name']
      ['description']
    ]

