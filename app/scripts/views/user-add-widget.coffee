define [
  './resource-add-widget'
  './textarea-field'
  './select-field'
  './relational-select-field'
  './script-field'
  './../models/user'
], (ResourceAddWidgetView, TextareaFieldView, SelectFieldView,
  RelationalSelectFieldView, ScriptFieldView, UserModel) ->

  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options

  # User Add Widget View
  # --------------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # user and updating an existing one.

  ##############################################################################
  # User Add Widget
  ##############################################################################

  class UserAddWidgetView extends ResourceAddWidgetView

    resourceName: 'user'
    resourceModel: UserModel

    attribute2fieldView:
      name: TextareaFieldView255
      page_content: ScriptFieldView

    primaryAttributes: [
      'first_name'
      'last_name'
    ]

    editableSecondaryAttributes: [
      'email'
      'affiliation'
      'markup_language'
      'page_content'
    ]

