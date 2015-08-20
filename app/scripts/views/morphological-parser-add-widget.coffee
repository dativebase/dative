define [
  './resource-add-widget'
  './textarea-field'
  './select-field'
  './relational-select-field'
  './morphology-select-via-search-field'
  './phonology-select-via-search-field'
  './language-model-select-via-search-field'
  './../models/morphological-parser'
], (ResourceAddWidgetView, TextareaFieldView, SelectFieldView,
  RelationalSelectFieldView, MorphologySelectViaSearchFieldView,
  PhonologySelectViaSearchFieldView, LanguageModelSelectViaSearchFieldView,
  MorphologicalParserModel) ->

  # Morphological Parser Add Widget View
  # ------------------------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # morphological parser and updating an existing one.

  ##############################################################################
  # Field sub-classes
  ##############################################################################

  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  class PhonologySelectFieldView extends RelationalSelectFieldView

    initialize: (options) ->
      options.optionsAttribute = 'phonologies'
      super options


  class MorphologySelectFieldView extends RelationalSelectFieldView

    initialize: (options) ->
      options.optionsAttribute = 'morphologies'
      super options


  class LanguageModelSelectFieldView extends RelationalSelectFieldView

    initialize: (options) ->
      options.optionsAttribute = 'morpheme_language_models'
      super options


  ##############################################################################
  # morphological parser Add Widget
  ##############################################################################

  class MorphologicalParserAddWidgetView extends ResourceAddWidgetView

    resourceName: 'morphologicalParser'
    resourceModel: MorphologicalParserModel

    resourcesNeededForAdd: ->
      [
        'morpheme_language_models'
        'phonologies'
        'morphologies'
      ]

    attribute2fieldView:
      name: TextareaFieldView255
      phonology: PhonologySelectViaSearchFieldView
      morphology: MorphologySelectViaSearchFieldView
      language_model: LanguageModelSelectViaSearchFieldView

    primaryAttributes: [
      'name'
      'description'
      'phonology'
      'morphology'
      'language_model'
    ]

    editableSecondaryAttributes: []

    getNewResourceDataSuccess: (data) ->
      data = @fixToolkits data
      super data

    fixToolkits: (data) ->
      data


