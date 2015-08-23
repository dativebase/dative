define [
  './resource-add-widget'
  './textarea-field'
  './select-field'
  './boolean-select-field'
  './relational-select-field'
  './subcorpus-select-via-search-field'
  './../models/morphology'
  './../utils/globals'
], (ResourceAddWidgetView, TextareaFieldView, SelectFieldView,
  BooleanSelectFieldView, RelationalSelectFieldView,
  SubcorpusSelectViaSearchFieldView, MorphologyModel, globals) ->


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
      if @model.get('id') # The GET /<resources>/<id>/edit case
        data.data.script_types = ['regex', 'lexc']
        data.data.booleans = [true, false]
      else
        data.script_types = ['regex', 'lexc']
        data.booleans = [true, false]
      super data

    attribute2fieldView:
      name: TextareaFieldView255
      lexicon_corpus: SubcorpusSelectViaSearchFieldView
      rules_corpus: SubcorpusSelectViaSearchFieldView
      script_type: ScriptTypeSelectFieldView
      extract_morphemes_from_rules_corpus: BooleanSelectFieldView
      rich_upper: BooleanSelectFieldView
      rich_lower: BooleanSelectFieldView
      include_unknowns: BooleanSelectFieldView

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

