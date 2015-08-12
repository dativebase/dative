define [
  './resource-as-row'
], (ResourceAsRowView) ->

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

