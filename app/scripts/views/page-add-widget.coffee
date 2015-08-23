define [
  './resource-add-widget'
  './textarea-field'
  './select-field'
  './relational-select-field'
  './script-field'
  './../models/page'
], (ResourceAddWidgetView, TextareaFieldView, SelectFieldView,
  RelationalSelectFieldView, ScriptFieldView, PageModel) ->


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


  # Page Add Widget View
  # -------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # page and updating an existing one.

  ##############################################################################
  # Page Add Widget
  ##############################################################################

  class PageAddWidgetView extends ResourceAddWidgetView

    resourceName: 'page'
    resourceModel: PageModel

    attribute2fieldView:
      name: TextareaFieldView255
      heading: TextareaFieldView255
      content: ScriptFieldView
      markup_language: MarkupLanguageFieldView

    primaryAttributes: [
      'name'
      'heading'
      'markup_language'
      'content'
    ]



