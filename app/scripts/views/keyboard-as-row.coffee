define [
  './resource-as-row'
], (ResourceAsRowView) ->

  class KeyboardAsRowView extends ResourceAsRowView

    resourceName: 'keyboard'

    orderedAttributes: [
      'name'
      'description'
      'id'
    ]

