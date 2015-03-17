define [
  './field-display'
  './value-representation'
], (FieldDisplayView, ValueRepresentationView) ->

  # Phonetic Transcription Field Display View
  # -----------------------------------------
  #
  # A view for displaying a phonetic transcription field.

  class PhoneticTranscriptionFieldDisplayView extends FieldDisplayView

    getContext: ->
      context = super
      context.value = @utils.encloseIfNotAlready context.value, '[', ']'
      context

