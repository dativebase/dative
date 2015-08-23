define [
  './resource-add-widget'
  './textarea-field'
  './select-field'
  './relational-select-field'
  './subcorpus-select-via-search-field'
  './morphology-select-via-search-field'
  './../models/language-model'
], (ResourceAddWidgetView, TextareaFieldView, SelectFieldView,
  RelationalSelectFieldView, SubcorpusSelectViaSearchFieldView,
  MorphologySelectViaSearchFieldView, LanguageModelModel) ->

  # Language Model Add Widget View
  # -------------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # language model and updating an existing one.

  ##############################################################################
  # Field sub-classes
  ##############################################################################

  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  class CorpusSelectFieldView extends RelationalSelectFieldView

    initialize: (options) ->
      options.optionsAttribute = 'corpora'
      super options


  class MorphologySelectFieldView extends RelationalSelectFieldView

    initialize: (options) ->
      options.optionsAttribute = 'morphologies'
      super options


  # TODO: Toolkit Select View should be tied to the Smoothing Select View, but
  # since OLD currently only supports one toolkit, this can be left for later.
  class ToolkitSelectFieldView extends SelectFieldView

    initialize: (options) ->
      options.optionsAttribute = 'toolkits'
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) -> o
      options.required = true
      super options


  class SmoothingSelectFieldView extends SelectFieldView

    initialize: (options) ->
      options.optionsAttribute = 'smoothingAlgorithms'
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) -> o
      super options


  class OrderSelectFieldView extends SelectFieldView

    initialize: (options) ->
      options.optionsAttribute = 'orders'
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) -> o
      options.required = true
      super options


  class BooleanSelectFieldView extends SelectFieldView

    initialize: (options) ->
      options.optionsAttribute = 'booleans'
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) -> o
      options.required = true
      super options


  ##############################################################################
  # Language model Add Widget
  ##############################################################################

  class LanguageModelAddWidgetView extends ResourceAddWidgetView

    resourceName: 'languageModel'
    resourceModel: LanguageModelModel

    attribute2fieldView:
      name: TextareaFieldView255
      toolkit: ToolkitSelectFieldView
      corpus: SubcorpusSelectViaSearchFieldView
      vocabulary_morphology: MorphologySelectViaSearchFieldView
      smoothing: SmoothingSelectFieldView
      order: OrderSelectFieldView
      categorial: BooleanSelectFieldView

    primaryAttributes: [
      'name'
      'description'
      'corpus'
      'toolkit'
      'order'
      'smoothing'
      'categorial'
      'vocabulary_morphology'
    ]

    editableSecondaryAttributes: []

    getNewResourceDataSuccess: (data) ->
      data = @fixToolkits data
      super data

    # Fix the server-provided object for creating new language models by
    # re-arranging some of the data and adding new data.  #
    # TODO: this is too ad hoc: that is, the available smoothing algorithms
    # will be determined by the selected LM toolkit.
    fixToolkits: (data) ->
      newData =
        smoothingAlgorithms: []
        orders: [2, 3, 4, 5]
        booleans: [true, false]
      iterator = if @model.get('id') then data.data else data
      for attr, val of iterator
        if attr is 'toolkits'
          newToolkits = []
          for toolkitName, toolkitObject of val
            newToolkits.push toolkitName
            newData.smoothingAlgorithms =
              newData.smoothingAlgorithms.concat toolkitObject.smoothing_algorithms
          newData[attr] = newToolkits
        else
          newData[attr] = val
      if @model.get('id') then data.data = newData else data = newData
      data

