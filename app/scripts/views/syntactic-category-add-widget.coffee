define [
  './resource-add-widget'
  './textarea-field'
  './select-field'
  './relational-select-field'
  './../models/syntactic-category'
], (ResourceAddWidgetView, TextareaFieldView, SelectFieldView,
  RelationalSelectFieldView, SyntacticCategoryModel) ->


  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  class TypeSelectFieldView extends SelectFieldView

    initialize: (options) ->
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) -> o
      options.optionsAttribute = 'syntactic_category_types'
      options.required = false
      super options


  # Syntactic Category Add Widget View
  # ----------------------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # syntactic category updating an existing one.

  ##############################################################################
  # Syntactic Category Add Widget
  ##############################################################################

  class SyntacticCategoryAddWidgetView extends ResourceAddWidgetView

    resourceName: 'syntacticCategory'
    resourceModel: SyntacticCategoryModel

    resourcesNeededForAdd: -> ['syntactic_category_types']

    attribute2fieldView:
      name: TextareaFieldView255
      type: TypeSelectFieldView

    primaryAttributes: [
      'name'
      'type'
      'description'
    ]


