define [
  './resource-select-via-search-input'
  './source-as-row'
  './../models/source'
], (ResourceSelectViaSearchInputView, SourceAsRowView, SourceModel) ->

  class SourceSelectViaSearchInputView extends ResourceSelectViaSearchInputView

    # Change these attributes in subclasses.
    resourceName: 'source'
    resourceModelClass: SourceModel
    resourceAsRowViewClass: SourceAsRowView

    resourceAsString: (resource) ->
      tmp = new @resourceModelClass resource
      try
        "#{tmp.getAuthor()} (#{tmp.getYear()})"
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

