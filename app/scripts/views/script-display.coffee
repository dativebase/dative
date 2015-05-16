define [
  './field-display'
  './script-representation'
], (FieldDisplayView, ScriptRepresentationView) ->

  # Person Field Display View
  # -------------------------
  #
  # A view for displaying a person field. Note: currently tailored only for
  # OLD-style "persons", i.e., objects with `first_name` and `last_name`
  # attributes.

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

