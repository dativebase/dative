define [
  './resource-add-widget'
  './textarea-field'
  './select-field'
  './relational-select-field'
  './../models/orthography'
], (ResourceAddWidgetView, TextareaFieldView, SelectFieldView,
  RelationalSelectFieldView, OrthographyModel) ->


  class BooleanSelectFieldView extends SelectFieldView

    initialize: (options) ->
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) -> "#{o}"
      super options


  class LowercaseSelectFieldView extends BooleanSelectFieldView

    initialize: (options) ->
      options.required = true
      options.optionsAttribute = 'lowercase'
      super options


  class InitialGlottalStopsSelectFieldView extends BooleanSelectFieldView

    initialize: (options) ->
      options.required = true
      options.optionsAttribute = 'initial_glottal_stops'
      super options


  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  # Orthography Add Widget View
  # ---------------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # orthography and updating an existing one.

  ##############################################################################
  # Orthography Add Widget
  ##############################################################################

  class OrthographyAddWidgetView extends ResourceAddWidgetView

    resourceName: 'orthography'
    resourceModel: OrthographyModel

    attribute2fieldView:
      name: TextareaFieldView255
      lowercase: LowercaseSelectFieldView
      initial_glottal_stops: InitialGlottalStopsSelectFieldView

    primaryAttributes: [
      'name'
      'orthography'
      'lowercase'
      'initial_glottal_stops'
    ]

    editableSecondaryAttributes: []

    # This returns the options for our forced-choice field views. we add
    # options for the `dative_file_type` and `utterance_type` attributes.
    getOptions: ->
      options = super
      options.lowercase = [
        true
        false
      ]
      options.initial_glottal_stops = [
        true
        false
      ]
      options

