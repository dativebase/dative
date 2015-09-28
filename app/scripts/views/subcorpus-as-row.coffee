define [
  './resource-as-row'
], (ResourceAsRowView) ->

  class SubcorpusAsRowView extends ResourceAsRowView

    resourceName: 'subcorpus'

    orderedAttributes: [
      'name'
      'description'
      'content'
      'tags'
      'form_search'
      'id'
    ]

    # Return a string representation for a given `attribute`/`value` pair of
    # this file.
    scalarTransform: (attribute, value) ->
      if @isHeaderRow
        @scalarTransformHeaderRow attribute, value
      else if value
        if attribute is 'tags'
          if value.length
            (t.name for t in value).join ', '
          else
            ''
        else if attribute is 'form_search'
          value.name
        else
          value
      else
        ''

