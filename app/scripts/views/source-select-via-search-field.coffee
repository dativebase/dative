define [
  './resource-select-via-search-field'
  './resource-select-via-search-input'
  './resource-as-row'
  './../models/source'
], (ResourceSelectViaSearchFieldView,
  ResourceSelectViaSearchInputView, ResourceAsRowView, SourceModel) ->


  class SourceAsRowView extends ResourceAsRowView

    resourceName: 'source'

    orderedAttributes: [
      'citation'
      'id'
      'key'
      'type'
      'crossref'
      'author'
      'editor'
      'year'
      'journal'
      'title'
      'booktitle'
      'chapter'
      'publisher'
      'school'
      'institution'
      'note'
    ]

    getModelValue: (attribute) ->
      switch attribute
        # citation isn't a real source value, but a constructed one
        when 'citation' then @model.getAuthorEditorYearDefaults()
        else @model.get attribute

    # Return `value` as a string, with the understanding that this is for a
    # header row, sow the value is probably going to be the attribute.
    scalarTransformHeaderRow: (attribute, value) ->
      switch attribute
        when 'citation' then 'citation'
        else value


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


  class SourceSelectViaSearchFieldView extends ResourceSelectViaSearchFieldView

    getInputView: ->
      new SourceSelectViaSearchInputView @context

    listenToEvents: ->
      super
      if @inputView
        @listenTo @inputView, 'validateMe', @myValidate

    myValidate: ->
      if @submitAttempted then @validate()

