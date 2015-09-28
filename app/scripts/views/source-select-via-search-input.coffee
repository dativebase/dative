define [
  './resource-select-via-search-input'
  './source-as-row'
  './../models/source'
  './../collections/sources'
], (ResourceSelectViaSearchInputView, SourceAsRowView, SourceModel,
  SourcesCollection) ->

  class SourceSelectViaSearchInputView extends ResourceSelectViaSearchInputView

    # Change these attributes in subclasses.
    resourceName: 'source'
    resourceModelClass: SourceModel
    resourcesCollectionClass: SourcesCollection
    resourceAsRowViewClass: SourceAsRowView

    resourceAsString: (resource) ->
      try
        (new @resourceModelClass(resource)).getAuthorEditorYearDefaults()
      catch
        ''

    # These are the `[<attribute]`s or `[<attribute>, <subattribute>]`s that we
    # "smartly" search over.
    smartStringSearchableFileAttributes: [
      ['id']
      ['key']
      ['type']
      ['crossref']
      ['author']
      ['editor']
      ['year']
      ['journal']
      ['title']
      ['booktitle']
      ['chapter']
      ['publisher']
      ['school']
      ['institution']
      ['note']
    ]

