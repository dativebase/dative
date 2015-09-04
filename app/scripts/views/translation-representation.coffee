define [
  './representation'
  './../templates/translation-representation'
], (RepresentationView, translationRepresentationTemplate) ->

  # Translation Representation View
  # -------------------------------
  #
  # A view for the representation of a single OLD translation (i.e., an object
  # with two relevant attributes: `transcription` and `grammaticality`).

  class TranslationRepresentationView extends RepresentationView

    template: translationRepresentationTemplate

    valueFormatter: (value, component='transcription') =>
      if @context.searchPatternsObject
        if component is 'transcription'
          regex = @context.searchPatternsObject[@context.attribute]?.transcription
          if regex
            @utils.highlightSearchMatch regex, value
          else
            value
        else
          regex = @context.searchPatternsObject[@context.attribute]?.grammaticality
          if regex
            @utils.highlightSearchMatch regex, value
          else
            value
      else
        value

