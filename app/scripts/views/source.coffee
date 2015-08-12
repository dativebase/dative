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
        when 'article' then @model.getAuthorYear()
        when 'book' then @model.getAuthorEditorYear()
        when 'booklet' then @titleRequired()
        when 'conference' then @model.getAuthorYear()
        when 'inbook' then @model.getAuthorEditorYear()
        when 'incollection' then @model.getAuthorYear()
        when 'inproceedings' then @model.getAuthorYear()
        when 'manual' then @titleRequired()
        when 'mastersthesis' then @model.getAuthorYear()
        when 'misc' then @model.getAuthorEditorYearDefaults()
        when 'phdthesis' then @model.getAuthorYear()
        when 'proceedings' then @titleYear()
        when 'techreport' then @model.getAuthorYear()
        when 'unpublished' then @titleRequired()
        else @model.getAuthorYear()

    # Try to return a string like "Chomsky and Halle (1968)", but just return
    # the title if author or year are missing.
    titleRequired: ->
      if @model.get('author') and @model.get('year')
        @model.getAuthorYear()
      else
        @model.get 'title'

    # Return a string like "The Sound Pattern of English (1968)".
    titleYear: -> "#{@model.get 'title'} (#{@model.get 'year'})"

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
      'datetime_modified'
      'id'
    ]
