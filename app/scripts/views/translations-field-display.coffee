define [
  './field-display'
  './translations-representation-set'
], (FieldDisplayView, TranslationsRepresentationSetView) ->

  # Translations Field Display View
  # -------------------------------
  #
  # A view for displaying an array of translation objects.

  class TranslationsFieldDisplayView extends FieldDisplayView

    getContext: ->
      _.extend(super,
        compatibilityAttribute: 'grammaticality'
        transcriptionAttribute: 'transcription'
      )

    getRepresentationView: ->
      new TranslationsRepresentationSetView @context

