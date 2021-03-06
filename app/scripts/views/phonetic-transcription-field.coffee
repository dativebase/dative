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

      @listenTo @model, 'warning:broad_phonetic_validation',
        @invalidFieldValueWarning

    # We have received a warning from our model that the phonetic transcription
    # value is invalid.
    invalidFieldValueWarning: (msg=null) ->
      if msg
        @$('.dative-field-warnings-container').show()
        @$('.dative-field-validation-warning-message').text "Warning: #{msg}"
      else
        @$('.dative-field-warnings-container').hide()

    setToModel: ->
      super
      if @submitAttempted
        @model.trigger 'transcriptionShouldValidate'
        @model.trigger 'narrowPhoneticTranscriptionShouldValidate'
        @model.trigger 'morphemeBreakShouldValidate'
      else
        # We call validate on the model here just so that warning events can be
        # triggered, if applicable.
        @model.validate()

