define [
  './resource-add-widget'
  './textarea-field'
  './select-field'
  './relational-select-field'
  './script-field'
  './../models/speaker'
], (ResourceAddWidgetView, TextareaFieldView, SelectFieldView,
  RelationalSelectFieldView, ScriptFieldView, SpeakerModel) ->


  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  # A <select>-based field view for the markup language select field.
  class MarkupLanguageFieldView extends SelectFieldView

    initialize: (options) ->
      options.required = true
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) -> o
      super options


  # Speaker Add Widget View
  # -----------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # speaker and updating an existing one.

  ##############################################################################
  # Speaker Add Widget
  ##############################################################################

  class SpeakerAddWidgetView extends ResourceAddWidgetView

    resourceName: 'speaker'
    resourceModel: SpeakerModel

    attribute2fieldView:
      name: TextareaFieldView255
      page_content: ScriptFieldView
      markup_language: MarkupLanguageFieldView

    # Attributes that are always displayed.
    primaryAttributes: [
      'first_name'
      'last_name'
      'dialect'
      'markup_language'
      'page_content'
    ]

