define [
  './resource'
  './morphological-parser-controls'
  './morphological-parser-add-widget'
  './person-field-display'
  './date-field-display'
  './object-with-name-field-display'
  './boolean-icon-display'
], (ResourceView, MorphologicalParserControlsView,
  MorphologicalParserAddWidgetView, PersonFieldDisplayView,
  DateFieldDisplayView, ObjectWithNameFieldDisplayView,
  BooleanIconFieldDisplayView) ->

  # Morphological Parser View
  # -------------------------
  #
  # For displaying individual morphological parsers.

  class MorphologicalParserView extends ResourceView

    resourceName: 'morphologicalParser'

    excludedActions: ['history']

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
      enterer: PersonFieldDisplayView
      modifier: PersonFieldDisplayView
      datetime_entered: DateFieldDisplayView
      datetime_modified: DateFieldDisplayView
      phonology: ObjectWithNameFieldDisplayView
      morphology: ObjectWithNameFieldDisplayView
      language_model: ObjectWithNameFieldDisplayView
      generate_succeeded: BooleanIconFieldDisplayView
      compile_succeeded: BooleanIconFieldDisplayView


