define ['./representation'], (RepresentationView) ->

  # Phonetic Transcription Representation View
  # ------------------------------------------
  #
  # A view for the representation of a phonetic transcription field.

  class PhoneticTranscriptionRepresentationView extends RepresentationView
    valueFormatter: (value) =>
      try
        @utils.encloseIfNotAlready value, '[', ']'
      catch
        value

