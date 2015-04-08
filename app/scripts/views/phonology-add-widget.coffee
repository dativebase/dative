define [
  './resource-add-widget'
  './textarea-field'
  './../models/phonology'
], (ResourceAddWidgetView, TextareaFieldView, PhonologyModel) ->

  # Phonology Add Widget View
  # -------------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # phonology and updating an existing one.

  ##############################################################################
  # Field sub-classes with max lengths
  ##############################################################################

  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options

  ##############################################################################
  # Phonology Add Widget
  ##############################################################################

  class PhonologyAddWidgetView extends ResourceAddWidgetView

    resourceName: 'phonology'
    resourceModel: PhonologyModel

    attribute2fieldView:
      name: TextareaFieldView255

    primaryAttributes: [
      'name'
      'description'
    ]

    editableSecondaryAttributes: [
      'script'
    ]

