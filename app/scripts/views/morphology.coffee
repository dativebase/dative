define [
  './resource'
  './morphology-add-widget'
  './person-field-display'
  './date-field-display'
  './object-with-name-field-display'
  './related-resource-field-display'
  './boolean-icon-display'
  './morphology-controls'
  './subcorpus'
  './related-model-representation'
  './../models/subcorpus'
  './../collections/subcorpora'
  './enterer-field-display'
  './modifier-field-display'
], (ResourceView, MorphologyAddWidgetView, PersonFieldDisplayView,
  DateFieldDisplayView, ObjectWithNameFieldDisplayView,
  RelatedResourceFieldDisplayView, BooleanIconFieldDisplayView,
  MorphologyControlsView, SubcorpusView, RelatedModelRepresentationView,
  SubcorpusModel, SubcorporaCollection, EntererFieldDisplayView,
  ModifierFieldDisplayView) ->


  class RelatedCorpusFieldDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'subcorpus'
    resourceModelClass: SubcorpusModel
    resourcesCollectionClass: SubcorporaCollection
    resourceViewClass: SubcorpusView


  class LexiconCorpusDisplayView extends RelatedCorpusFieldDisplayView

    attributeName: 'lexicon_corpus'


  class RulesCorpusDisplayView extends RelatedCorpusFieldDisplayView

    attributeName: 'rules_corpus'


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
      enterer: EntererFieldDisplayView
      modifier: ModifierFieldDisplayView
      datetime_entered: DateFieldDisplayView
      datetime_modified: DateFieldDisplayView
      lexicon_corpus: LexiconCorpusDisplayView
      rules_corpus: RulesCorpusDisplayView
      compile_succeeded: BooleanIconFieldDisplayView

    excludedActions: ['history', 'data']

    controlsViewClass: MorphologyControlsView

