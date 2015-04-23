define [
  './resource'
  './form-add-widget'
  './person-field-display'
  './date-field-display'
  './object-with-name-field-display'
  './array-of-objects-with-name-field-display'
], (ResourceView, FormAddWidgetView, PersonFieldDisplayView,
  DateFieldDisplayView, ObjectWithNameFieldDisplayView,
  ArrayOfObjectsWithNameFieldDisplayView) ->

  # Form View
  # --------------
  #
  # For displaying individual forms.

  class FormView extends ResourceView

    resourceName: 'form'

    resourceAddWidgetView: FormAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: [
      'narrow_phonetic_transcription'
      'phonetic_transcription'
      'transcription'
      'morpheme_break'
      'morpheme_gloss'
      'translations'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'elicitation_method'
      'tags'
      'syntactic_category'
      'date_elicited'
      'speaker'
      'elicitor'
      'enterer'
      'datetime_entered'
      'modifier'
      'datetime_modified'
      'verifier'
      'source'
      'files'
      'collections'
    ]

    attribute2displayView:
      tags: ArrayOfObjectsWithNameFieldDisplayView
      form_search: ObjectWithNameFieldDisplayView
      enterer: PersonFieldDisplayView
      modifier: PersonFieldDisplayView
      datetime_entered: DateFieldDisplayView
      datetime_modified: DateFieldDisplayView
      files: ArrayOfObjectsWithNameFieldDisplayView

