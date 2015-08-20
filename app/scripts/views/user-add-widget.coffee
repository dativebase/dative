define [
  './resource-add-widget'
  './textarea-field'
  './password-field'
  './select-field'
  './relational-select-field'
  './script-field'
  './../models/user'
  './../utils/globals'
], (ResourceAddWidgetView, TextareaFieldView, PasswordFieldView,
  SelectFieldView, RelationalSelectFieldView, ScriptFieldView, UserModel,
  globals) ->


  imAdmin = ->
    try
      globals.applicationSettings.get('loggedInUser').role is 'administrator'
    catch
      false


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


  class UsernameFieldView extends TextareaFieldView255

    visibilityCondition: -> imAdmin()

  # A <select>-based field view for the markup language select field.
  class RoleFieldView extends SelectFieldView

    initialize: (options) ->
      options.required = true
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) -> o
      super options

    visibilityCondition: -> imAdmin()


  class UserPasswordFieldView extends PasswordFieldView

    visibilityCondition: -> @imAdminOrImResource()


  class UserPasswordConfirmFieldView extends UserPasswordFieldView

    visibilityCondition: -> @imAdminOrImResource()

    initialize: (options={}) ->
      options.confirmField = true
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

    resourcesNeededForAdd: ->
      [
        'orthographies'
        'roles'
        'markup_languages'
      ]

    attribute2fieldView:
      name: TextareaFieldView255
      page_content: ScriptFieldView
      markup_language: MarkupLanguageFieldView
      role: RoleFieldView
      username: UsernameFieldView
      password: UserPasswordFieldView
      password_confirm: UserPasswordConfirmFieldView

    primaryAttributes: [
      'first_name'
      'last_name'
      'email'
      'role'
      'username'
      'password'
      'password_confirm'
    ]

    editableSecondaryAttributes: [
      'affiliation'
      'markup_language'
      'page_content'
    ]

    getNewResourceData: ->
      console.log 'in getNewResourceData'
      super

