define [
  './resource-add-widget'
  './textarea-field'
  './select-field'
  './relational-select-field'
  './../models/elicitation-method'
], (ResourceAddWidgetView, TextareaFieldView, SelectFieldView,
  RelationalSelectFieldView, ElicitationMethodModel) ->


  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  # ElicitationMethod Add Widget View
  # --------------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # elicitation method and updating an existing one.

  ##############################################################################
  # Elicitation Method Add Widget
  ##############################################################################

  class ElicitationMethodAddWidgetView extends ResourceAddWidgetView

    resourceName: 'elicitationMethod'
    resourceModel: ElicitationMethodModel

    attribute2fieldView:
      name: TextareaFieldView255

    primaryAttributes: [
      'name'
      'description'
    ]

