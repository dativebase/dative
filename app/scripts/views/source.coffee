define [
  './resource'
  './related-resource-field-display'
  './related-resource-representation'
  './source-add-widget'
  './date-field-display'
  './file-field-display'
  './../models/source'
  './../collections/sources'
], (ResourceView, RelatedResourceFieldDisplayView,
  RelatedResourceRepresentationView, SourceAddWidgetView, DateFieldDisplayView,
  FileFieldDisplayView, SourceModel, SourcesCollection) ->

  # Non-circular Related Source Field Display View
  # ----------------------------------------------
  #
  # Non-circular because it doesn't import `SourceView`, which imports it. In
  # contrast, see /views/related-source-field-display.coffee
  #
  # For displaying a source as a field/attribute of another resource, such that
  # the source is displayed as a link that, when clicked, causes the resource to
  # be displayed in a dialog box.

  class SourceFieldDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'source'
    attributeName: 'source'
    resourceModelClass: SourceModel
    resourcesCollectionClass: SourcesCollection

    # We do this on purpose.
    resourceViewClass: null

    resourceAsString: (resource) ->
      tmp = new @resourceModelClass resource
      try
        "#{tmp.getAuthor()} (#{tmp.getYear()})"
      catch
        ''

    getContext: ->
      context = super
      context.getRelatedResourceId = @getRelatedResourceId
      context

    getRelatedResourceId: ->
      @context.model.get('crossref_source').id


  # Source View
  # -----------
  #
  # For displaying individual sources.

  class SourceView extends ResourceView

    resourceName: 'source'

    resourceAddWidgetView: SourceAddWidgetView

    getHeaderTitle: ->
      id = @model.get 'id'
      if id
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
      else
        'New Source'

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
      file: FileFieldDisplayView
      crossref_source: SourceFieldDisplayView

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

