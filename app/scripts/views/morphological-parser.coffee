define [
  './resource'
  './phonology'
  './morphology'
  './language-model'
  './morphological-parser-controls'
  './morphological-parser-add-widget'
  './person-field-display'
  './date-field-display'
  './object-with-name-field-display'
  './enterer-field-display'
  './modifier-field-display'
  './related-resource-field-display'
  './boolean-icon-display'
  './../models/phonology'
  './../models/morphology'
  './../models/language-model'
  './../collections/phonologies'
  './../collections/morphologies'
  './../collections/language-models'
], (ResourceView, PhonologyView, MorphologyView, LanguageModelView,
  MorphologicalParserControlsView, MorphologicalParserAddWidgetView,
  PersonFieldDisplayView, DateFieldDisplayView, ObjectWithNameFieldDisplayView,
  EntererFieldDisplayView, ModifierFieldDisplayView,
  RelatedResourceFieldDisplayView, BooleanIconFieldDisplayView, PhonologyModel,
  MorphologyModel, LanguageModelModel, PhonologiesCollection,
  MorphologiesCollection, LanguageModelsCollection) ->


  class PhonologyFieldDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'phonology'
    attributeName: 'phonology'
    resourceModelClass: PhonologyModel
    resourcesCollectionClass: PhonologiesCollection
    resourceViewClass: PhonologyView


  class MorphologyFieldDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'morphology'
    attributeName: 'morphology'
    resourceModelClass: MorphologyModel
    resourcesCollectionClass: MorphologiesCollection
    resourceViewClass: MorphologyView


  class LanguageModelFieldDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'languageModel'
    attributeName: 'language_model'
    resourceModelClass: LanguageModelModel
    resourcesCollectionClass: LanguageModelsCollection
    resourceViewClass: LanguageModelView


  # Morphological Parser View
  # -------------------------
  #
  # For displaying individual morphological parsers.

  class MorphologicalParserView extends ResourceView

    resourceName: 'morphologicalParser'

    excludedActions: ['history', 'data']

    controlsViewClass: MorphologicalParserControlsView

    resourceAddWidgetView: MorphologicalParserAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: [
      'name'
      'description'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'phonology'
      'morphology'
      'language_model'
      'generate_succeeded'
      'generate_message'
      'generate_attempt'
      'compile_succeeded'
      'compile_message'
      'compile_attempt'
      'morphology_rare_delimiter'
      'enterer'
      'modifier'
      'datetime_entered'
      'datetime_modified'
      'id'
      'UUID'
    ]

    # Map attribute names to display view class names.
    attribute2displayView:
      enterer: EntererFieldDisplayView
      modifier: ModifierFieldDisplayView
      datetime_entered: DateFieldDisplayView
      datetime_modified: DateFieldDisplayView
      phonology: PhonologyFieldDisplayView
      morphology: MorphologyFieldDisplayView
      language_model: LanguageModelFieldDisplayView
      generate_succeeded: BooleanIconFieldDisplayView
      compile_succeeded: BooleanIconFieldDisplayView


