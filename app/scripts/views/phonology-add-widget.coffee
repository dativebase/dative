define [
  './resource-add-widget'
  './textarea-field'
  './script-field'
  './../models/phonology'
], (ResourceAddWidgetView, TextareaFieldView, ScriptFieldView,
  PhonologyModel) ->

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
      script: ScriptFieldView

    primaryAttributes: [
      'name'
      'description'
      'script'
    ]

    editableSecondaryAttributes: []

    # It is crucial that we remove any U+00a0 characters from the script.
    setToModel: ->
      super
      newValue = @model.get('script')
        .replace(/\u00a0/g, '')
        .replace(/\u000d/g, '')
      @model.set 'script', newValue

