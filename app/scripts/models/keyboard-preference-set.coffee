define [
  './resource'
  './keyboard'
], (ResourceModel, KeyboardModel) ->

  # Keyboard Preferences Model
  # --------------------------
  #
  # Client-side-stored model for assigning keyboards to specific form fields.

  class KeyboardPreferenceSetModel extends ResourceModel

    # Transform plain keyboard objects into Backbone `KeyboardModel` instances.
    objects2models: ->

      systemWideKeyboardObject = @get 'system_wide_keyboard'
      if systemWideKeyboardObject
        @set('system_wide_keyboard',
          (new KeyboardModel(systemWideKeyboardObject)))

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

      # A system-wide keyboard that will be used when entering data into any
      # field. The field-specific keyboard listed below should trump this one
      # when those fields are focused.
      system_wide_keyboard: null

      # A keyboard for entering transcription values.
      transcription_keyboard: null

      # A keyboard for entering *phonetic* transcription values.
      phonetic_transcription_keyboard: null

      # A keyboard for entering *narrow* phonetic transcription values.
      narrow_phonetic_transcription_keyboard: null

      # A keyboard for entering morpheme break values.
      morpheme_break_keyboard: null

    editableAttributes: [
      'system_wide_keyboard'
      'transcription_keyboard'
      'phonetic_transcription_keyboard'
      'narrow_phonetic_transcription_keyboard'
      'morpheme_break_keyboard'
    ]

