define [
  './resource-as-row'
], (ResourceAsRowView) ->

  class SearchAsRowView extends ResourceAsRowView

    resourceName: 'search'

    orderedAttributes: [
      'id'
      'name'
      'description'
    ]

