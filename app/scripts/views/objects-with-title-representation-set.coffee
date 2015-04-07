define [
  './representation-set'
  './value-representation'
], (RepresentationSetView, ValueRepresentationView) ->

  # Translations Representation Set View
  # ------------------------------------
  #
  # A view for a *set* of translation representations.

  class TranslationsRepresentationSetView extends RepresentationSetView

    # Override `RepresentationSetView`'s default with a translation-appropriate
    # representation view.
    getRepresentationView: (representationContext) ->
      new ValueRepresentationView representationContext

    # Override `RepresentationSetView`'s default with translation-appropriate
    # context attributes.
    getRepresentationContext: (object) ->
      _.extend(super,
        compatibilityAttribute: @compatibilityAttribute
        compatibilityClass:     @getClass @compatibilityAttribute
        compatibilityTitle:     @getTooltip "#{@attribute}.#{@compatibilityAttribute}"
        compatibilityValue:     object[@compatibilityAttribute]

        transcriptionAttribute: @transcriptionAttribute
        transcriptionClass:     @getClass @transcriptionAttribute
        transcriptionTitle:     @getTooltip "#{@attribute}.#{@transcriptionAttribute}"
        transcriptionValue:     object[@transcriptionAttribute]
      )


