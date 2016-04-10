define [
  './resource-add-widget'
  './textarea-field'
  './keyboard-field'
  './../models/keyboard'
], (ResourceAddWidgetView, TextareaFieldView, KeyboardFieldView,
  KeyboardModel) ->


  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  # Keyboard Add Widget View
  # ------------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # keyboard and updating an existing one.

  ##############################################################################
  # Keyboard Add Widget
  ##############################################################################

  class KeyboardAddWidgetView extends ResourceAddWidgetView

    resourceName: 'keyboard'
    resourceModel: KeyboardModel

    attribute2fieldView:
      name: TextareaFieldView255
      keyboard: KeyboardFieldView

    primaryAttributes: [
      'name'
      'description'
      'keyboard'
    ]

