define [
  './resource'
  './source-add-widget'
  './date-field-display'
  './../utils/bibtex'
], (ResourceView, SourceAddWidgetView, DateFieldDisplayView, BibTeXUtils) ->

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
        when 'booklet' then @titleRequired()
        when 'conference' then @authorYear()
        when 'inbook' then @authorEditorYear()
        when 'incollection' then @authorYear()
        when 'inproceedings' then @authorYear()
        when 'manual' then @titleRequired()
        when 'mastersthesis' then @authorYear()
        when 'misc' then @misc()
        when 'phdthesis' then @authorYear()
        when 'proceedings' then @titleYear()
        when 'techreport' then @authorYear()
        when 'unpublished' then @titleRequired()
        else @authorYear()

    # Return a string like "Chomsky and Halle (1968)"
    authorYear: ->
      author = @model.get 'author'
      authorCitation = BibTeXUtils.getNameInCitationForm author
      "#{authorCitation} (#{@model.get 'year'})"

    # Return a string like "Chomsky and Halle (1968)", using editor names if
    # authors are unavailable.
    authorEditorYear: ->
      if @model.get 'author'
        name = @model.get 'author'
      else
        name = @model.get 'editor'
      nameCitation = BibTeXUtils.getNameInCitationForm name
      "#{nameCitation} (#{@model.get 'year'})"

    # Try to return a string like "Chomsky and Halle (1968)", but just return
    # the title if author or year are missing.
    titleRequired: ->
      if @model.get('author') and @model.get('year')
        @authorYear()
      else
        @model.get 'title'

    # Return a string like "The Sound Pattern of English (1968)".
    titleYear: -> "#{@model.get 'title'} (#{@model.get 'year'})"

    # Try to return a string like "Chomsky and Halle (1968)", but replace
    # either the author or the year with filler text, if needed.
    misc: ->
      author = @model.get 'author'
      if author
        auth = BibTeXUtils.getNameInCitationForm author
      else
        auth = 'no author'
      year = @model.get 'year'
      yr = if year then year else 'no year'
      "#{auth} (#{yr})"

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

