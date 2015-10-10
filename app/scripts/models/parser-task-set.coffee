define [
  './resource'
  './phonology'
  './morphology'
  './morphological-parser'
], (ResourceModel, PhonologyModel, MorphologyModel, MorphologicalParserModel) ->

  # Parser Tasks Model
  # ------------------
  #
  # Client-side-stored model for assigning form-related tasks to parsers and
  # their subcomponents, i.e., phonologies and morphologies.

  class ParserTaskSetModel extends ResourceModel

    initialize: (attributes, options) ->
      super attributes, options
      # @objects2models()

    # Transform plain objects into Backbone models for parsers, phonologies and
    # morphologies.
    objects2models: ->
      transcriptionParserObject = @get 'transcription_parser'
      if transcriptionParserObject
        @set('transcription_parser',
          (new MorphologicalParserModel(transcriptionParserObject)))

      phoneticTranscriptionParserObject = @get 'phonetic_transcription_parser'
      if phoneticTranscriptionParserObject
        @set('phonetic_transcription_parser',
          (new MorphologicalParserModel(phoneticTranscriptionParserObject)))

      narrowPhoneticTranscriptionParserObject =
        @get 'narrow_phonetic_transcription_parser'
      if narrowPhoneticTranscriptionParserObject
        @set('narrow_phonetic_transcription_parser',
          (new MorphologicalParserModel(narrowPhoneticTranscriptionParserObject)))

      toTranscriptionPhonologyObject = @get 'to_transcription_phonology'
      if toTranscriptionPhonologyObject
        @set('to_transcription_phonology',
          (new PhonologyModel(toTranscriptionPhonologyObject)))

      toPhoneticTranscriptionPhonologyObject =
        @get 'to_phonetic_transcription_phonology'
      if toPhoneticTranscriptionPhonologyObject
        @set('to_phonetic_transcription_phonology',
          (new PhonologyModel(toPhoneticTranscriptionPhonologyObject)))

      toNarrowPhoneticTranscriptionPhonologyObject =
        @get 'to_narrow_phonetic_transcription_phonology'
      if toNarrowPhoneticTranscriptionPhonologyObject
        @set('to_narrow_phonetic_transcription_phonology',
          (new PhonologyModel(toNarrowPhoneticTranscriptionPhonologyObject)))

      recognizerMorphologyObject = @get 'recognizer_morphology'
      if recognizerMorphologyObject
        @set('recognizer_morphology',
          (new MorphologyModel(recognizerMorphologyObject)))

    resourceName: 'parserTaskSet'

    clientSideOnlyModel: true

    defaults: ->
      id: @guid()

      # A morphological parser for parsing transcription values
      transcription_parser: null

      # A morphological parser for parsing *phonetic* transcription values
      phonetic_transcription_parser: null

      # A morphological parser for parsing *narrow* phonetic transcription
      # values
      narrow_phonetic_transcription_parser: null

      # A phonology for generating transcriptions from morphological analyses.
      to_transcription_phonology: null

      # A phonology for generating phonetic transcriptions from morphological
      # analyses.
      to_phonetic_transcription_phonology: null

      # A phonology for generating narrow phonetic transcriptions from
      # morphological analyses.
      to_narrow_phonetic_transcription_phonology: null

      # A morphology for recognizing morphological analyses.
      recognizer_morphology: null

    editableAttributes: [
      'transcription_parser'
      'phonetic_transcription_parser'
      'narrow_phonetic_transcription_parser'
      'to_transcription_phonology'
      'to_phonetic_transcription_phonology'
      'to_narrow_phonetic_transcription_phonology'
      'recognizer_morphology'
    ]

