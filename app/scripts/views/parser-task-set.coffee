define [
  './resource'
  './phonology'
  './morphology'
  './morphological-parser'
  './parser-task-set-add-widget'
  './related-resource-field-display'
  './related-resource-representation'
  './../models/phonology'
  './../models/morphology'
  './../models/morphological-parser'
  './../collections/phonologies'
  './../collections/morphologies'
  './../collections/morphological-parsers'
], (ResourceView, PhonologyView, MorphologyView, MorphologicalParserView,
  ParserTaskSetAddWidgetView, RelatedResourceFieldDisplayView,
  RelatedResourceRepresentationView, PhonologyModel, MorphologyModel,
  MorphologicalParserModel, PhonologiesCollection, MorphologiesCollection,
  MorphologicalParsersCollection) ->

  class MyRelatedResourceRepresentationView extends RelatedResourceRepresentationView

    getEmptyValue: -> 'not specified'


  class TranscriptionParserFieldDisplayView extends RelatedResourceFieldDisplayView

    relatedResourceRepresentationViewClass: MyRelatedResourceRepresentationView
    resourceName: 'morphologicalParser'
    attributeName: 'transcription_parser'
    resourceModelClass: MorphologicalParserModel
    resourcesCollectionClass: MorphologicalParsersCollection
    resourceViewClass: MorphologicalParserView
    shouldBeHidden: -> false
    nullResourceAsString: (resource) -> 'not specified'


  class PhoneticTranscriptionParserFieldDisplayView extends TranscriptionParserFieldDisplayView

    attributeName: 'phonetic_transcription_parser'


  class NarrowPhoneticTranscriptionParserFieldDisplayView extends TranscriptionParserFieldDisplayView

    attributeName: 'narrow_phonetic_transcription_parser'


  class ToTranscriptionPhonologyFieldDisplayView extends RelatedResourceFieldDisplayView

    relatedResourceRepresentationViewClass: MyRelatedResourceRepresentationView
    resourceName: 'phonology'
    attributeName: 'to_transcription_phonology'
    resourceModelClass: PhonologyModel
    resourcesCollectionClass: PhonologiesCollection
    resourceViewClass: PhonologyView
    shouldBeHidden: -> false
    nullResourceAsString: (resource) -> 'not specified'


  class ToPhoneticTranscriptionPhonologyFieldDisplayView extends ToTranscriptionPhonologyFieldDisplayView

    attributeName: 'to_phonetic_transcription_phonology'


  class ToNarrowPhoneticTranscriptionPhonologyFieldDisplayView extends ToTranscriptionPhonologyFieldDisplayView

    attributeName: 'to_narrow_phonetic_transcription_phonology'


  class RecognizerMorphologyFieldDisplayView extends RelatedResourceFieldDisplayView

    relatedResourceRepresentationViewClass: MyRelatedResourceRepresentationView
    resourceName: 'morphology'
    attributeName: 'recognizer_morphology'
    resourceModelClass: MorphologyModel
    resourcesCollectionClass: MorphologiesCollection
    resourceViewClass: MorphologyView
    shouldBeHidden: -> false
    nullResourceAsString: (resource) -> 'not specified'


  # Parser Task Set View
  # --------------------
  #
  # For displaying a "parser task set", i.e., a set of tasks assigned to
  # parsers and their subcomponents, i.e., phonologies and morphologies. These
  # tasks are relevant to form creation. For example, a parser can be chosen as
  # the transcription parser; this parser will be used to parser user-entered
  # transcription values and suggest morpheme break and morpheme gloss values
  # in real time.

  class ParserTaskSetView extends ResourceView

    initialize: (options={}) ->
      options.labelsAlwaysVisible = true
      super options

    resourceName: 'parserTaskSet'

    resourceAddWidgetView: ParserTaskSetAddWidgetView

    getHeaderTitle: -> 'Your Parser Tasks'

    excludedActions: [
      'history'
      'controls'
      'data'
      'settings'
      'delete'
      'duplicate'
      'export'
    ]

    # Attributes that are always displayed.
    primaryAttributes: [
      'transcription_parser'
      'phonetic_transcription_parser'
      'narrow_phonetic_transcription_parser'
      'to_transcription_phonology'
      'to_phonetic_transcription_phonology'
      'to_narrow_phonetic_transcription_phonology'
      'recognizer_morphology'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: []

    # Map attribute names to display view class names.
    attribute2displayView:
      transcription_parser: TranscriptionParserFieldDisplayView
      phonetic_transcription_parser: PhoneticTranscriptionParserFieldDisplayView
      narrow_phonetic_transcription_parser: NarrowPhoneticTranscriptionParserFieldDisplayView
      to_transcription_phonology: ToTranscriptionPhonologyFieldDisplayView
      to_phonetic_transcription_phonology: ToPhoneticTranscriptionPhonologyFieldDisplayView
      to_narrow_phonetic_transcription_phonology: ToNarrowPhoneticTranscriptionPhonologyFieldDisplayView
      recognizer_morphology: RecognizerMorphologyFieldDisplayView

