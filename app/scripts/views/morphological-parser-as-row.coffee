define [
  './resource-as-row'
], (ResourceAsRowView) ->

  class MorphologicalParserAsRowView extends ResourceAsRowView

    resourceName: 'morphologicalParser'

    orderedAttributes: [
      'name'
      'description'
      'phonology'
      'morphology'
      'language_model'
      'id'
    ]

    # Return a string representation for a given `attribute`/`value` pair of
    # this file.
    scalarTransform: (attribute, value) ->
      if @isHeaderRow
        @scalarTransformHeaderRow attribute, value
      else if value
        if attribute in ['phonology', 'morphology', 'language_model']
          value.name
        else
          value
      else
        ''


