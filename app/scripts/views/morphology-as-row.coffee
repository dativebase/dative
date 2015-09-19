define [
  './resource-as-row'
], (ResourceAsRowView) ->

  class MorphologyAsRowView extends ResourceAsRowView

    resourceName: 'morphology'

    orderedAttributes: [
      'name'
      'description'
      'lexicon_corpus'
      'rules_corpus'
      'id'
    ]

    # Return a string representation for a given `attribute`/`value` pair of
    # this file.
    scalarTransform: (attribute, value) ->
      if @isHeaderRow
        @scalarTransformHeaderRow attribute, value
      else if value
        if attribute in ['lexicon_corpus', 'rules_corpus']
          value.name
        else
          value
      else
        ''

