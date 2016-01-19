define [
  './transcription-base-field'
], (TranscriptionBaseFieldView) ->

  # Narrow Phonetic Transcription Field View
  # ----------------------------------------

  class NarrowPhoneticTranscriptionFieldView extends TranscriptionBaseFieldView

    listenToEvents: ->
      super

      # One of our fellow transcription-type fields is telling us to validate.
      @listenTo @model, 'narrowPhoneticTranscriptionShouldValidate', @validate

    setToModel: ->
      super
      if @submitAttempted
        @model.trigger 'transcriptionShouldValidate'
        @model.trigger 'phoneticTranscriptionShouldValidate'
        @model.trigger 'morphemeBreakShouldValidate'

