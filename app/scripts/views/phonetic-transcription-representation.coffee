define ['./representation'], (RepresentationView) ->

  # Phonetic Transcription Representation View
  # ------------------------------------------
  #
  # A view for the representation of a phonetic transcription field.

  class PhoneticTranscriptionRepresentationView extends RepresentationView
    initialize: (@context) ->
      @context.value = @utils.encloseIfNotAlready context.value, '[', ']'

