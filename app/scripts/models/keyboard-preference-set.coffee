define [
  './resource'
  './keyboard'
], (ResourceModel, KeyboardModel) ->

  # Keyboard Preferences Model
  # --------------------------
  #
  # Client-side-stored model for assigning keyboards to specific form fields.

  class KeyboardPreferenceSetModel extends ResourceModel

    # Transform plain objects into Backbone models for parsers, phonologies and
    # morphologies.
    objects2models: ->

      transcriptionKeyboardObject = @get 'transcription_keyboard'
      if transcriptionKeyboardObject
        @set('transcription_keyboard',
          (new KeyboardModel(transcriptionKeyboardObject)))

      phoneticTranscriptionKeyboardObject =
        @get 'phonetic_transcription_keyboard'
      if phoneticTranscriptionKeyboardObject
        @set('phonetic_transcription_keyboard',
          (new KeyboardModel(phoneticTranscriptionKeyboardObject)))

      narrowPhoneticTranscriptionKeyboardObject =
        @get 'narrow_phonetic_transcription_keyboard'
      if narrowPhoneticTranscriptionKeyboardObject
        @set('narrow_phonetic_transcription_keyboard',
          (new KeyboardModel(narrowPhoneticTranscriptionKeyboardObject)))

      morphemeBreakKeyboardObject = @get 'morpheme_break_keyboard'
      if morphemeBreakKeyboardObject
        @set('morpheme_break_keyboard',
          (new KeyboardModel(morphemeBreakKeyboardObject)))

    resourceName: 'parserTaskSet'

    clientSideOnlyModel: true

    defaults: ->
      id: @guid()

      # A keyboard for entering transcription values.
      transcription_keyboard: null

      # A keyboard for entering *phonetic* transcription values.
      phonetic_transcription_keyboard: null

      # A keyboard for entering *narrow* phonetic transcription values.
      narrow_phonetic_transcription_keyboard: null

      # A keyboard for entering morpheme break values.
      morpheme_break_keyboard: null

    editableAttributes: [
      'transcription_keyboard'
      'phonetic_transcription_keyboard'
      'narrow_phonetic_transcription_keyboard'
      'morpheme_break_keyboard'
    ]

