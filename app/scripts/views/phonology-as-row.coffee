define [
  './resource-as-row'
], (ResourceAsRowView) ->

  class PhonologyAsRowView extends ResourceAsRowView

    resourceName: 'phonology'

    orderedAttributes: [
      'name'
      'description'
      'script'
      'id'
    ]

    # Return a string representation for a given `attribute`/`value` pair of
    # this file.
    scalarTransform: (attribute, value) ->
      if @isHeaderRow
        @scalarTransformHeaderRow attribute, value
      else if value
        value
      else
        ''

