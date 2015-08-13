define [
  './resource'
  './subcorpus'
  './morphology'
  './language-model-add-widget'
  './person-field-display'
  './date-field-display'
  './object-with-name-field-display'
  './enterer-field-display'
  './modifier-field-display'
  './related-resource-field-display'
  './boolean-icon-display'
  './../models/subcorpus'
  './../models/morphology'
  './../collections/subcorpora'
  './../collections/morphologies'
], (ResourceView, SubcorpusView, MorphologyView, LanguageModelAddWidgetView,
  PersonFieldDisplayView, DateFieldDisplayView, ObjectWithNameFieldDisplayView,
  EntererFieldDisplayView, ModifierFieldDisplayView,
  RelatedResourceFieldDisplayView, BooleanIconFieldDisplayView, SubcorpusModel,
  MorphologyModel, SubcorporaCollection, MorphologiesCollection) ->


  class CorpusFieldDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'subcorpus'
    attributeName: 'corpus'
    resourceModelClass: SubcorpusModel
    resourcesCollectionClass: SubcorporaCollection
    resourceViewClass: SubcorpusView


  class MorphologyFieldDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'morphology'
    attributeName: 'vocabulary_morphology'
    resourceModelClass: MorphologyModel
    resourcesCollectionClass: MorphologiesCollection
    resourceViewClass: MorphologyView


  # Language Model View
  # -------------------
  #
  # For displaying individual language models.

  class LanguageModelView extends ResourceView

    resourceName: 'languageModel'

    resourceAddWidgetView: LanguageModelAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: [
      'name'
      'description'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'corpus'
      'toolkit'
      'order'
      'smoothing'
      'vocabulary_morphology'
      'restricted'
      'categorial'
      'morpheme_delimiters'
      'generate_succeeded'
      'generate_message'
      'generate_attempt'
      'perplexity'
      'perplexity_attempt'
      'perplexity_computed'
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
      corpus: CorpusFieldDisplayView
      vocabulary_morphology: MorphologyFieldDisplayView
      generate_succeeded: BooleanIconFieldDisplayView

