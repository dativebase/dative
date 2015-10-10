define [
  './resource-add-widget'
  './phonology-select-via-search-field'
  './morphology-select-via-search-field'
  './morphological-parser-select-via-search-field'
  './../models/parser-task-set'
], (ResourceAddWidgetView, PhonologySelectViaSearchFieldView,
  MorphologySelectViaSearchFieldView,
  MorphologicalParserSelectViaSearchFieldView, ParserTaskSetModel) ->

  # Parser Task Set Add Widget View
  # -------------------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # parser task set or updating an existing one.

  ##############################################################################
  # Parser Task Set Add Widget
  ##############################################################################

  class ParserTaskSetAddWidgetView extends ResourceAddWidgetView

    resourceName: 'parserTaskSet'
    resourceModel: ParserTaskSetModel

    attribute2fieldView:
      transcription_parser: MorphologicalParserSelectViaSearchFieldView
      phonetic_transcription_parser: MorphologicalParserSelectViaSearchFieldView
      narrow_phonetic_transcription_parser: MorphologicalParserSelectViaSearchFieldView
      to_transcription_phonology: PhonologySelectViaSearchFieldView
      to_phonetic_transcription_phonology: PhonologySelectViaSearchFieldView
      to_narrow_phonetic_transcription_phonology: PhonologySelectViaSearchFieldView
      recognizer_morphology: MorphologySelectViaSearchFieldView

    primaryAttributes: [
      'transcription_parser'
      'phonetic_transcription_parser'
      'narrow_phonetic_transcription_parser'
      'to_transcription_phonology'
      'to_phonetic_transcription_phonology'
      'to_narrow_phonetic_transcription_phonology'
      'recognizer_morphology'
    ]

