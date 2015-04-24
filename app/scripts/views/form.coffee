define [
  './resource'
  './form-add-widget'
  './person-field-display'
  './date-field-display'
  './object-with-name-field-display'
  './array-of-objects-with-name-field-display'
  './judgement-value-field-display'
  './morpheme-break-field-display'
  './morpheme-gloss-field-display'
  './phonetic-transcription-field-display'
  './grammaticality-value-field-display'
  './translations-field-display'
  './source-field-display'
  './array-of-objects-with-title-field-display'
], (ResourceView, FormAddWidgetView, PersonFieldDisplayView,
  DateFieldDisplayView, ObjectWithNameFieldDisplayView,
  ArrayOfObjectsWithNameFieldDisplayView, JudgementValueFieldDisplayView,
  MorphemeBreakFieldDisplayView, MorphemeGlossFieldDisplayView,
  PhoneticTranscriptionFieldDisplayView, GrammaticalityValueFieldDisplayView,
  TranslationsFieldDisplayView, SourceFieldDisplayView,
  ArrayOfObjectsWithTitleFieldDisplayView) ->

  # Form View
  # --------------
  #
  # For displaying individual forms.

  class FormView extends ResourceView

    className: 'dative-resource-widget dative-form-object dative-paginated-item
      dative-widget-center ui-corner-all'

    initialize: (options) ->
      super
      switch @activeServerType
        when 'FieldDB'
          @attribute2displayView = @attribute2displayViewFieldDB
        when 'OLD'
          @attribute2displayView = @attribute2displayViewOLD
      @headerAlwaysVisible = false

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
      'comments'
      'speaker_comments'
      'syntax'
      'semantics'
      'status'
      'elicitation_method'
      'tags'
      'syntactic_category'
      'syntactic_category_string'
      'break_gloss_category'
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
      'UUID'
      'id'
    ]

    attribute2displayView: {}

    attribute2displayViewFieldDB:
      utterance: JudgementValueFieldDisplayView
      morphemes: MorphemeBreakFieldDisplayView
      gloss: MorphemeGlossFieldDisplayView
      dateElicited: DateFieldDisplayView
      dateEntered: DateFieldDisplayView
      dateModified: DateFieldDisplayView

    attribute2displayViewOLD:
      narrow_phonetic_transcription: PhoneticTranscriptionFieldDisplayView
      phonetic_transcription: PhoneticTranscriptionFieldDisplayView
      transcription: GrammaticalityValueFieldDisplayView
      translations: TranslationsFieldDisplayView
      morpheme_break: MorphemeBreakFieldDisplayView
      morpheme_gloss: MorphemeGlossFieldDisplayView
      syntactic_category: ObjectWithNameFieldDisplayView
      elicitation_method: ObjectWithNameFieldDisplayView
      source: SourceFieldDisplayView
      date_elicited: DateFieldDisplayView
      datetime_entered: DateFieldDisplayView
      datetime_modified: DateFieldDisplayView
      speaker: PersonFieldDisplayView
      elicitor: PersonFieldDisplayView
      enterer: PersonFieldDisplayView
      modifier: PersonFieldDisplayView
      verifier: PersonFieldDisplayView
      collections: ArrayOfObjectsWithTitleFieldDisplayView
      tags: ArrayOfObjectsWithNameFieldDisplayView
      files: ArrayOfObjectsWithNameFieldDisplayView

    # Override this `resource` method so that there is no header title for form
    # resources.
    getHeaderTitle: -> ''

