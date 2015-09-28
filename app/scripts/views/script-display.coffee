define [
  './field-display'
  './script-representation'
], (FieldDisplayView, ScriptRepresentationView) ->

  # Script Field Display View
  # -------------------------
  #
  # A view for displaying a script field, e.g., for a phonology.

  class ScriptFieldDisplayView extends FieldDisplayView

    fieldDisplayLabelContainerClass: 'dative-field-display-label-container top'
    fieldDisplayRepresentationContainerClass:
      'dative-field-display-representation-container full-width script'

    getRepresentationView: ->
      new ScriptRepresentationView @context

    guify: ->
      super
      @$('.dative-field-display-representation-container.script')
        .css 'border-color': @constructor.jQueryUIColors().defBo

