define [
  './resource-add-widget'
  './textarea-field'
  './select-field'
  './relational-select-field'
  './../models/tag'
], (ResourceAddWidgetView, TextareaFieldView, SelectFieldView,
  RelationalSelectFieldView, TagModel) ->


  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  # Tag Add Widget View
  # -------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # tag and updating an existing one.

  ##############################################################################
  # Tag Add Widget
  ##############################################################################

  class TagAddWidgetView extends ResourceAddWidgetView

    resourceName: 'tag'
    resourceModel: TagModel

    attribute2fieldView:
      name: TextareaFieldView255

    primaryAttributes: [
      'name'
      'description'
    ]


