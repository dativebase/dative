define [
  './resource-add-widget'
  './textarea-field'
  './select-field'
  './relational-select-field'
  './../models/morphology'
], (ResourceAddWidgetView, TextareaFieldView, SelectFieldView,
  RelationalSelectFieldView, MorphologyModel) ->


  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  class ScriptTypeSelectFieldView extends SelectFieldView

    initialize: (options) ->
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) -> o
      options.required = true
      super options


  class CorpusSelectFieldView extends RelationalSelectFieldView

    initialize: (options) ->
      options.optionsAttribute = 'corpora'
      super options

  # Morphology Add Widget View
  # --------------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # morphology and updating an existing one.

  ##############################################################################
  # Morphology Add Widget
  ##############################################################################

  class MorphologyAddWidgetView extends ResourceAddWidgetView

    resourceName: 'morphology'
    resourceModel: MorphologyModel

    storeOptionsDataGlobally: (data) ->
      data.script_types = ['regex', 'lexc']
      super data

    attribute2fieldView:
      name: TextareaFieldView255
      lexicon_corpus: CorpusSelectFieldView
      rules_corpus: CorpusSelectFieldView
      script_type: ScriptTypeSelectFieldView

    primaryAttributes: [
      'name'
      'description'
      'lexicon_corpus'
      'rules_corpus'
      'rules'
      'script_type'
    ]

    editableSecondaryAttributes: [
      'extract_morphemes_from_rules_corpus'
      'rich_upper'
      'rich_lower'
      'include_unknowns'
    ]

