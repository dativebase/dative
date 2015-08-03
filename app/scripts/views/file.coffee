define [
  './resource'
  './file-add-widget'
  './field-display'
  './person-field-display'
  './speaker-field-display'
  './date-field-display'
  './object-with-name-field-display'
  './array-of-objects-with-name-field-display'
  './bytes-field-display'
  './file-data'
  './related-resource-field-display'
  './related-user-field-display'
  './enterer-field-display'
  './modifier-field-display'
  './../utils/globals'
], (ResourceView, FileAddWidgetView, FieldDisplayView, PersonFieldDisplayView,
  SpeakerFieldDisplayView, DateFieldDisplayView, ObjectWithNameFieldDisplayView,
  ArrayOfObjectsWithNameFieldDisplayView, BytesFieldDisplayView,
  FileDataView, RelatedResourceFieldDisplayView, RelatedUserFieldDisplayView,
  EntererFieldDisplayView, ModifierFieldDisplayView, globals) ->


  class ElicitorFieldDisplayView extends RelatedUserFieldDisplayView

    attributeName: 'elicitor'


  class FileFieldDisplayView extends FieldDisplayView

    getContext: ->
      context = super
      try
        if context.value.name
          context.value = context.value.name
        else if context.value.filename
          context.value = context.value.filename
        else
          context.value = "File #{context.value.id}"
      catch
        context.value = ''
      context

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

  class FileView extends ResourceView

    initialize: (options) ->
      super options
      @allowedFileTypes = globals.applicationSettings.get 'allowedFileTypes'

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
      'url'
      'parent_file'
      'password'
      'start'
      'end'
      'description'
      'utterance_type'
      'speaker'
      'elicitor'
      'tags'
      #'forms'
      'date_elicited'
      'enterer'
      'modifier'
      'datetime_entered'
      'datetime_modified'
      'UUID'
      'id'
    ]

    attribute2displayView:
      speaker: SpeakerFieldDisplayView
      elicitor: ElicitorFieldDisplayView
      enterer: EntererFieldDisplayView
      modifier: ModifierFieldDisplayView
      date_elicited: DateFieldDisplayView
      datetime_entered: DateFieldDisplayView
      datetime_modified: DateFieldDisplayView
      size: BytesFieldDisplayView
      tags: ArrayOfObjectsWithNameFieldDisplayView
      name: NameFieldDisplayView
      filename: FilenameFieldDisplayView
      parent_file: FileFieldDisplayView

    MIMEType2type: (MIMEType) ->
      if MIMEType in @allowedFileTypes
        [type, subtype] = MIMEType.split '/'
        if type is 'application' then subtype else type
      else
        null

    getHeaderTitle: ->
      id = @model.get 'id'
      if id then "File #{id}" else "New File"

    getResourceIcon: (fileTypeIconClass=null) ->
      fileTypeIconClass = fileTypeIconClass or @getFileTypeIconClass()
      fileTypeIcon = "<i class='fa fa-lg #{fileTypeIconClass}'></i>"
      if @model.get('url')
        externalLinkIcon = "<i class='fa fa-lg fa-external-link'></i>"
      else
        externalLinkIcon = ''
      if @model.get('parent_file')
        subintervalIcon = "<i class='fa fa-lg fa-scissors'></i>"
      else
        subintervalIcon = ''
      "#{fileTypeIcon}#{externalLinkIcon}#{subintervalIcon}"

    listenToEvents: ->
      super
      @listenTo @model, 'change:MIME_type', @refreshFileDataViewButton
      @listenTo @model, 'change:url', @refreshFileDataViewButton
      @listenTo @model, 'change:parent_file', @refreshFileDataViewButton

    getFileTypeIconClass: ->
      MIMEType = @model.get 'MIME_type'
      if MIMEType and @MIMEType2type MIMEType
        type = @MIMEType2type MIMEType
        "fa-file-#{type}-o"
      else if @model.get('url')
        "fa-file-video-o"
      else if @model.get('parent_file')
        try
          type = @MIMEType2type @model.get('parent_file').MIME_type
          "fa-file-#{type}-o"
        catch
          "fa-file-audio-o"
      else
        "fa-file-o"

    refreshFileDataViewButton: ->
      fileTypeIconClass = @getFileTypeIconClass()
      $('button.file-data i')
        .removeClass()
        .addClass "fa fa-fw #{fileTypeIconClass}"
      $('span.resource-icon').html @getResourceIcon(fileTypeIconClass)

    # Return an <i> tag with the correct Font Awesome icon for the file type.
    # Note: we assume that all externally hosted files are videos (which may be
    # false).
    getIconI: ->
      MIMEType = @model.get 'MIME_type'
      if MIMEType and @MIMEType2type MIMEType
        type = @MIMEType2type MIMEType
        "<i class='fa fa-fw fa-file-#{type}-o'></i>"
      else if @model.get('url')
        "<i class='fa fa-fw fa-file-video-o'></i>"
      else
        "<i class='fa fa-fw fa-file-o'></i>"

    getContext: ->
      context = super
      iconI = @getIconI()
      if iconI
        context.dataTypeIcon = iconI
      context

    excludedActions: [
      'history'
      'controls'
      'duplicate'
    ]

    fileDataViewClass: FileDataView

    focusFirstUpdateViewField: ->
      @$('.update-resource-widget')
        .find('textarea, button.file-upload-button')
        .filter(':visible').first().focus()

