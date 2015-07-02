define [
  './resource'
  './file-add-widget'
  './field-display'
  './person-field-display'
  './date-field-display'
  './object-with-name-field-display'
  './array-of-objects-with-name-field-display'
  './bytes-field-display'
  './file-data'
], (ResourceView, FileAddWidgetView, FieldDisplayView, PersonFieldDisplayView,
  DateFieldDisplayView, ObjectWithNameFieldDisplayView,
  ArrayOfObjectsWithNameFieldDisplayView, BytesFieldDisplayView,
  FileDataView) ->

  class NameFieldDisplayView extends FieldDisplayView

    render: ->
      super
      @$('.dative-field-display-representation-container')
        .css 'overflow-x', 'scroll'
      @

  # We only want to display the `filename` field if its value is different from
  # `name`. The following describes how `filename` and `name` are valuated by
  # the OLD.
  # 1. base64 JSON creation:            name is identical to filename
  # 2. multipart/form-data creation:    name is identical to filename
  # 3. externally hosted:               name is provided by creator; there is
  #                                       no filename
  # 4. subinterval-referencing:         name is provided by creator, or
  #                                       defaults to `parent_file.filename`
  class FilenameFieldDisplayView extends NameFieldDisplayView

    shouldBeHidden: ->
      shouldBeHidden_ = super
      if not shouldBeHidden_
        if @context.value is @model.get 'name'
          shouldBeHidden_ = true
      shouldBeHidden_


  # File View
  # --------------
  #
  # For displaying individual files.
  #
  # On file.name and file.filename:

  class FileView extends ResourceView

    resourceName: 'file'

    resourceAddWidgetView: FileAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: [
      'name'
      'filename'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'lossy_filename'
      'size'
      'MIME_type'
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
      'enterer'
      'modifier'
      'datetime_entered'
      'datetime_modified'
      'UUID'
      'id'
    ]

    attribute2displayView:
      speaker: PersonFieldDisplayView
      elicitor: PersonFieldDisplayView
      enterer: PersonFieldDisplayView
      modifier: PersonFieldDisplayView
      date_elicited: DateFieldDisplayView
      datetime_entered: DateFieldDisplayView
      datetime_modified: DateFieldDisplayView
      size: BytesFieldDisplayView
      tags: ArrayOfObjectsWithNameFieldDisplayView
      name: NameFieldDisplayView
      filename: FilenameFieldDisplayView

    MIMEType2type:
      'application/pdf': 'pdf'
      'image/gif': 'image'
      'image/jpeg': 'image'
      'image/png': 'image'
      'audio/mpeg': 'audio'
      'audio/ogg': 'audio'
      'audio/x-wav': 'audio'
      'video/mpeg': 'video'
      'video/mp4': 'video'
      'video/ogg': 'video'
      'video/quicktime': 'video'
      'video/x-ms-wmv': 'video'

    getHeaderTitle: ->
      id = @model.get 'id'
      if id then "File #{id}" else "New File"

    # Return an <i> tag with the correct Font Awesome icon for the file type.
    getIconI: ->
      MIMEType = @model.get 'MIME_type'
      if MIMEType and MIMEType of @MIMEType2type
        type = @MIMEType2type[MIMEType]
        "<i class='fa fa-fw fa-file-#{type}-o'></i>"
      else
        null

    getContext: ->
      context = super
      iconI = @getIconI()
      if iconI
        context.dataTypeIcon = iconI
      context

    excludedActions: [
      'history'
      'controls'
    ]

    fileDataViewClass: FileDataView

    focusFirstUpdateViewField: ->
      @$('.update-resource-widget')
        .find('textarea, span.ui-selectmenu-button')
        .filter(':visible').first().focus()

