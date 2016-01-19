define [
  './transcription-base-field'
], (TranscriptionBaseFieldView) ->

  # Phonetic Transcription Field View
  # ---------------------------------

  class PhoneticTranscriptionFieldView extends TranscriptionBaseFieldView

    listenToEvents: ->
      super

      # One of our fellow transcription-type fields is telling us to validate.
      @listenTo @model, 'phoneticTranscriptionShouldValidate', @validate

    setToModel: ->
      super
      if @submitAttempted
        @model.trigger 'transcriptionShouldValidate'
        @model.trigger 'narrowPhoneticTranscriptionShouldValidate'
        @model.trigger 'morphemeBreakShouldValidate'

