define [
  './resource-as-row'
], (ResourceAsRowView) ->

  class LanguageModelAsRowView extends ResourceAsRowView

    resourceName: 'languageModel'

    orderedAttributes: [
      'name'
      'description'
      'corpus'
      'vocabulary_morphology'
      'smoothing'
      'id'
    ]

    # Return a string representation for a given `attribute`/`value` pair of
    # this file.
    scalarTransform: (attribute, value) ->
      if @isHeaderRow
        @scalarTransformHeaderRow attribute, value
      else if value
        if attribute in ['corpus', 'vocabulary_morphology']
          value.name
        else
          value
      else
        ''

