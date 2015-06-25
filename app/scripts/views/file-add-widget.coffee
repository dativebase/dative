define [
  './resource-add-widget'
  './textarea-field'
  './relational-select-field'
  './multiselect-field'
  './person-select-field'
  './user-select-field'
  './date-field'
  './../models/file'
], (ResourceAddWidgetView, TextareaFieldView, RelationalSelectFieldView,
  MultiselectFieldView, PersonSelectFieldView, UserSelectFieldView,
  DateFieldView, FileModel) ->

  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  # File Add Widget View
  # --------------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # file and updating an existing one.

  ##############################################################################
  # File Add Widget
  ##############################################################################

  class FileAddWidgetView extends ResourceAddWidgetView

    resourceName: 'file'
    resourceModel: FileModel

    # Maps attributes to their appropriate FieldView subclasses.
    # This is where field-specific configuration should go.
    attribute2fieldView:
      elicitor:                      UserSelectFieldView
      speaker:                       PersonSelectFieldView
      date_elicited:                 DateFieldView
      tags:                          MultiselectFieldView

    primaryAttributes: [
      'filename'
    ]

    editableSecondaryAttributes: [
      'description'
      'utterance_type'
      'speaker'
      'elicitor'
      'tags'
      #'forms'
      'date_elicited'
      'url'
      'password'
      'parent_file'
      'start'
      'end'
    ]

