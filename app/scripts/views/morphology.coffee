define [
  './resource'
  './morphology-add-widget'
  './person-field-display'
  './date-field-display'
  './object-with-name-field-display'
  './field-display'
  './boolean-icon-display'
  './morphology-controls'
  './subcorpus'
  './related-model-representation'
  './../models/subcorpus'
], (ResourceView, MorphologyAddWidgetView, PersonFieldDisplayView,
  DateFieldDisplayView, ObjectWithNameFieldDisplayView, FieldDisplayView,
  BooleanIconFieldDisplayView, MorphologyControlsView, SubcorpusView,
  RelatedModelRepresentationView, SubcorpusModel) ->

  class RelatedCorpusDisplayView extends FieldDisplayView

    getRepresentationView: ->
      @context.relatedModelClass = SubcorpusModel
      @context.relatedModelViewClass = SubcorpusView
      new RelatedModelRepresentationView @context


  # Morphology View
  # ---------------
  #
  # For displaying individual morphologies.

  class MorphologyView extends ResourceView

    resourceName: 'morphology'

    resourceAddWidgetView: MorphologyAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: [
      'name'
      'description'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'lexicon_corpus'
      'rules_corpus'
      'script_type'
      'extract_morphemes_from_rules_corpus'
      'rules'
      'rich_upper'
      'rich_lower'
      'include_unknowns'
      'enterer'
      'modifier'
      'datetime_entered'
      'datetime_modified'
      'compile_succeeded'
      'compile_message'
      'compile_attempt'
      'generate_attempt'
      'rules_generated'
      'UUID'
      'id'
    ]

    # Map attribute names to display view class names.
    attribute2displayView:
      enterer: PersonFieldDisplayView
      modifier: PersonFieldDisplayView
      datetime_entered: DateFieldDisplayView
      datetime_modified: DateFieldDisplayView
      lexicon_corpus: RelatedCorpusDisplayView
      rules_corpus: RelatedCorpusDisplayView
      compile_succeeded: BooleanIconFieldDisplayView

    excludedActions: ['history']

    controlsViewClass: MorphologyControlsView

