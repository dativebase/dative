define ['./representation'], (RepresentationView) ->

  # Phonetic Transcription Representation View
  # ------------------------------------------
  #
  # A view for the representation of a phonetic transcription field.

  class PhoneticTranscriptionRepresentationView extends RepresentationView

    valueFormatter: (value) =>
      if @context.searchPatternsObject
        regex = @context.searchPatternsObject[@context.attribute]
        if regex
          value = @utils.highlightSearchMatch regex, value
        else
          value = value
      else
        value = value
      try
        @utils.encloseIfNotAlready value, '[', ']'
      catch
        value

