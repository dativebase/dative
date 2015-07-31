define [
  './resource'
  './source-add-widget'
  './date-field-display'
], (ResourceView, SourceAddWidgetView, DateFieldDisplayView) ->

  # Source View
  # -----------
  #
  # For displaying individual sources.

  class SourceView extends ResourceView

    resourceName: 'source'

    resourceAddWidgetView: SourceAddWidgetView

    getHeaderTitle: ->
      switch @model.get('type')
        when 'article' then @authorYear()
        when 'book' then @authorEditorYear()
        when 'booklet' then @model.get 'title'
        when 'conference' then @authorYear()
        when 'inbook' then @authorEditorYear()
        when 'incollection' then @authorYear()
        when 'inproceedings' then @authorYear()
        when 'manual' then @model.get 'title'
        when 'mastersthesis' then @authorYear()
        when 'misc' then @misc()
        when 'phdthesis' then @authorYear()
        when 'proceedings' then @titleYear()
        when 'techreport' then @authorYear()
        when 'unpublished' then @model.get 'author'

    authorYear: -> "#{@model.get 'author'} (#{@model.get 'year'})"

    titleYear: -> "#{@model.get 'title'} (#{@model.get 'year'})"

    misc: ->
      author = @model.get 'author'
      auth = if author then author else 'no author'
      year = @model.get 'year'
      yr = if year then year else 'no year'
      "#{auth} (#{yr})"

    authorEditorYear: ->
      if @model.get 'author'
        auth = @model.get 'author'
      else
        auth = @model.get 'editor'
      "#{auth} (#{@model.get 'year'})"

    # Map attribute names to display view class names.
    attribute2displayView:
      datetime_modified: DateFieldDisplayView

    # Attributes that are always displayed.
    primaryAttributes: [
      'key'
      'type'
      'file'
      'crossref_source'
      'crossref'
      'author'
      'editor'
      'year'
      'journal'
      'title'
      'booktitle'
      'chapter'
      'pages'
      'publisher'
      'school'
      'institution'
      'note'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'volume'
      'number'
      'month'
      'series'
      'address'
      'edition'
      'annote'
      'howpublished'
      'key_field'
      'organization'
      'type_field'
      'url'
      'affiliation'
      'abstract'
      'contents'
      'copyright'
      'ISBN'
      'ISSN'
      'keywords'
      'language'
      'location'
      'LCCN'
      'mrnumber'
      'price'
      'size'
    ]

