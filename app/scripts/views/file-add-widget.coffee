define [
  './resource-add-widget'
  './textarea-field'
  './relational-select-field'
  './multi-element-tag-field'
  './person-select-field'
  './user-select-field'
  './date-field'
  './file-data-upload-field'
  './file-data'
  './select-field'
  './resource-select-via-search-field'
  './file-select-via-search-input'
  './../models/file'
], (ResourceAddWidgetView, TextareaFieldView,
  RelationalSelectFieldView, MultiElementTagFieldView, PersonSelectFieldView,
  UserSelectFieldView, DateFieldView, FileDataUploadFieldView, FileData,
  SelectFieldView, ResourceSelectViaSearchFieldView,
  FileSelectViaSearchInputView, FileModel) ->


  # The typed textarea field view is a textarea field that is visible only when
  # the file is of a certain type, i.e., stored on the web service, hosted
  # elsewhere, or subinterval-referencing.
  class StoredOnServerTextareaFieldView extends TextareaFieldView

    getCrucialAttributes: -> ['dative_file_type', 'MIME_type']

    visibilityCondition: ->
      @model.get('dative_file_type') is 'storedOnTheServer'


  # A <select>-based field view for the file's utterance type. This field will
  # only be visible when the file is audio or video.
  class UtteranceTypeSelectFieldView extends SelectFieldView

    initialize: (options) ->
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) -> o
      super options

    getCrucialAttributes: -> ['MIME_type']

    visibilityCondition: -> @model.isAudioVideo()


  # A <select>-based field view for the file's elicitor. This is only displayed
  # when the file is audio or video.
  class ElicitorSelectFieldView extends UserSelectFieldView

    getCrucialAttributes: -> ['MIME_type']

    visibilityCondition: -> @model.isAudioVideo()


  # A <select>-based field view for the file's speaker. This is only displayed
  # when the file is audio or video.
  class SpeakerSelectFieldView extends PersonSelectFieldView

    getCrucialAttributes: -> ['MIME_type']

    visibilityCondition: -> @model.isAudioVideo()


  # A <select>-based field view for the Dative file type, i.e.,
  # `storedOnTheServer`, `storedOnAnotherServer`, or
  # `referencesASubintervalOfAnotherFile`. Note: this field view is only
  # visible when we are adding/creating a new file; it is not visible on
  # update.
  class DativeFileTypeFieldView extends SelectFieldView

    getCrucialAttributes: -> ['dative_file_type', 'MIME_type']

    initialize: (options) ->
      options.required = true
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) => @utils.camel2regular o
      super options

    visibilityCondition: -> @addUpdateType is 'add'


  class FilenameFieldView extends StoredOnServerTextareaFieldView

    listenToEvents: ->
      super
      @listenTo @model, 'change:filename', @filenameChanged

    filenameChanged: ->
      @$("textarea.#{@context.class}").val @model.get('filename')


  class NonLocalFileAttributeFieldView extends StoredOnServerTextareaFieldView

    visibilityCondition: ->
      @model.get('dative_file_type') is 'storedOnAnotherServer'

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  class NonLocalOrSubintervalFileAttributeFieldView extends StoredOnServerTextareaFieldView

    visibilityCondition: ->
      @model.get('dative_file_type') in ['storedOnAnotherServer',
        'referencesASubintervalOfAnotherFile']

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  class SubintervalReferencingFileAttributeFieldView extends StoredOnServerTextareaFieldView

    visibilityCondition: ->
      @model.get('dative_file_type') is 'referencesASubintervalOfAnotherFile'

    # This class is used for start and end values. These should be floats, so
    # we parse them to floats here.
    getValueFromDOM: ->
      result = super
      try
        value = parseFloat result[@attribute]
        if isNaN(value) then value = ''
        result[@attribute] = value
      result


  class ParentFileData extends FileData

    initialize: (options) ->
      options.parentFile = true
      super options


  class ParentFileSearchInputView extends FileSelectViaSearchInputView

    # Change these attributes in subclasses.
    resourceName: 'file'
    resourceModelClass: FileModel

    # Instead of using the (default) `RelatedResourceRepresentationView` to
    # display the selected parent file, we use `ParentFileData` defined above.
    resourceSelectedViewClass: ParentFileData

    # We don't want a wrapper class because the `ParentFileData` view provides
    # that functionality for us; e.g., the "deselect" button.
    selectedResourceWrapperViewClass: null

    # Make the container for the `ParentFileData` instance have a nice border.
    containerAppearance: ($container) ->
      $container
        .addClass 'dative-shadowed-widget ui-widget ui-widget-content
          ui-corner-all'
        .css 'border-color': @constructor.jQueryUIColors().defBo

    # With `ParentFileData` view being used to display the selected file, the
    # model we pass has to be the model of the selected file, not the model of
    # the child file, which would be the default.
    getModelForSelectedResourceView: -> @selectedResourceModel

    # When the user selects a parent file, we want to give the child file the
    # same MIME type as the parent. We also set the child's start value to 0.
    setSelectedToModel: (resourceAsRowView) ->
      @model.set 'MIME_type', resourceAsRowView.model.get('MIME_type')
      @model.trigger 'setAttribute', 'start', 0
      super resourceAsRowView

    unsetSelectedFromModel: ->
      @model.set 'MIME_type', ''
      super

    # Do something special after the view for the selected resource has been
    # rendered.
    renderSelectedResourceViewPost: ->
      @$('audio, video')
        .on 'loadedmetadata', ((event) => @metadataLoaded event)

    metadataLoaded: (event) ->
      @model.trigger 'setAttribute', 'end', event.currentTarget.duration

    onClose: ->
      @$('audio, video').off 'loadedmetadata'
      super


  class ParentFileSearchFieldView extends ResourceSelectViaSearchFieldView

    getInputView: ->
      new ParentFileSearchInputView @context

    listenToEvents: ->
      super
      if @inputView
        @listenTo @inputView, 'validateMe', @myValidate

    myValidate: ->
      if @submitAttempted then @validate()

    getCrucialAttributes: -> ['dative_file_type']

    visibilityCondition: ->
      @model.get('dative_file_type') is 'referencesASubintervalOfAnotherFile'


  class TypedFileDataUploadFieldView extends FileDataUploadFieldView

    getCrucialAttributes: -> ['dative_file_type', 'MIME_type']

    visibilityCondition: ->
      @addUpdateType is 'add' and
      @model.get('dative_file_type') is 'storedOnTheServer'


  ##############################################################################
  # File Add Widget View
  ##############################################################################
  #
  # View for a widget containing inputs and controls for creating a new
  # file and updating an existing one.

  class FileAddWidgetView extends ResourceAddWidgetView

    initialize: (options) ->
      super options
      @lastSetAutoName = '' # The last value we auto-set for `model.get 'name'`
      @previouslySet =
        storedOnTheServer: {}
        storedOnAnotherServer: {}
        referencesASubintervalOfAnotherFile: {}
      @defaults = @model.defaults()

    resourceName: 'file'
    resourceModel: FileModel

    # Maps attributes to their appropriate FieldView subclasses.
    # This is where field-specific configuration should go.
    attribute2fieldView:
      elicitor:                      ElicitorSelectFieldView
      speaker:                       SpeakerSelectFieldView
      date_elicited:                 DateFieldView
      tags:                          MultiElementTagFieldView
      file_data:                     TypedFileDataUploadFieldView
      dative_file_type:              DativeFileTypeFieldView
      start:                         SubintervalReferencingFileAttributeFieldView
      end:                           SubintervalReferencingFileAttributeFieldView
      url:                           NonLocalFileAttributeFieldView
      password:                      NonLocalFileAttributeFieldView
      name:                          NonLocalOrSubintervalFileAttributeFieldView
      utterance_type:                UtteranceTypeSelectFieldView
      parent_file:                   ParentFileSearchFieldView

    # We listen to a `setAttribute` event triggered on our `@model`. We do this
    # because the `ParentFileSearchFieldView` will trigger this when it wants
    # us to set `start` and/or `end` values.
    # NOTE: a subview could directly change *model* attributes itself; however,
    # that is not what we want here; we want to set the values in the GUI
    # inputs (whereafter they will be auto-set to the model).
    listenToEvents: ->
      super
      @listenTo @model, 'setAttribute', @setAttribute
      @listenTo @model, 'change:parent_file', @parentFileChanged
      @listenTo @model, 'change:start', @setAutoName
      @listenTo @model, 'change:end', @setAutoName
      @listenTo @model, 'change:dative_file_type', @dativeFileTypeChanged

    # Typed attributes encode which attributes are relevant to a given Dative
    # file type. This information is used in `rememberAndClear` and `restore`.
    typedAttributes:
      storedOnTheServer:
        mine: ['MIME_type', 'filename', 'size']
        other: ['url', 'name', 'parent_file', 'start', 'end']
      storedOnAnotherServer:
        mine: ['url', 'name']
        other: ['MIME_type', 'filename', 'size', 'parent_file', 'start', 'end']
      referencesASubintervalOfAnotherFile:
        mine: ['parent_file', 'name', 'start', 'end']
        other: ['url', 'MIME_type', 'filename', 'size']

    # When the Dative file type changes, we reset certain attributes to their
    # defaults while remembering the specified values (in case the file type is
    # reverted) and we restore any previously remembered values that are
    # specific to this type.
    dativeFileTypeChanged: ->
      @rememberAndClear()
      @restore()
      @model.trigger 'fileDataChanged'

    # Remember current "other" values and reset them to their defaults.
    rememberAndClear: ->
      previousDativeFileType = @model.previous 'dative_file_type'
      currentDativeFileType = @model.get 'dative_file_type'
      for attr in @typedAttributes[currentDativeFileType].other
        @previouslySet[previousDativeFileType][attr] = @model.get attr
        @model.set attr, @defaults[attr], {silent: true}

    # Restore previously remembered attr-values that are appropriate to this
    # Dative file type.
    restore: ->
      dativeFileType = @model.get 'dative_file_type'
      attrList = @typedAttributes[dativeFileType].mine
      for attr in attrList
        try
          @model.set attr, @previouslySet[dativeFileType][attr], {silent: true}

    parentFileChanged: ->
      # We must trigger an event like this on the model directly so that the
      # `FileDataView` instance will update its data display. This is necessary
      # because if the file data view is listening on the model's 'change'
      # event, its `hasUpdated` values will be altered by the effects of
      # `setAutoName` here.
      @model.trigger 'fileDataChanged'
      @setAutoName()

    # When certain subinterval-referencing-relevant attributes are changed, we
    # give the file a default name based on that of its parent file and its
    # start and end values. We only do this if the `name` attribute is not yet
    # valuated.
    setAutoName: ->
      if @model.get('parent_file') and
      (@model.get('name') in ['', @lastSetAutoName, undefined])
        parentFilename = @model.get('parent_file').filename
        [filename, extension] = @utils.getFilenameAndExtension parentFilename
        extension = if extension then ".#{extension}" else ''
        start = @model.get('start') or 0
        end = @model.get('end') or 0
        newAutoName = "#{filename}-#{start}s-to-#{end}s#{extension}"
        @lastSetAutoName = newAutoName
        @setAttribute 'name', newAutoName

    # Valuate the (assumedly) textarea input with `name=attr` to `val`. Useful
    # for letting one field (sub)view set the values of another.
    setAttribute: (attr, val) ->
      @$("textarea[name=#{attr}]")
        .val val
        .trigger 'input'

    primaryAttributes: [
      'dative_file_type'
      'file_data'
      'url'
      'parent_file'
      'name'
      'password'
      'start'
      'end'
      'description'
    ]

    editableSecondaryAttributes: [
      'utterance_type'
      'speaker'
      'elicitor'
      'tags'
      'date_elicited'
      #'forms'
    ]

    # This returns the options for our forced-choice field views. we add
    # options for the `dative_file_type` and `utterance_type` attributes.
    getOptions: ->
      options = super
      options.dative_file_types = [
        'storedOnTheServer'
        'storedOnAnotherServer'
        'referencesASubintervalOfAnotherFile'
      ]
      options.utterance_types = [
        'Object Language Utterance'
        'Metalanguage Utterance'
        'Mixed Utterance'
      ]
      options

    # Since the first visible field view in the secondary field views may be a
    # tag-it-based view, we need to trigger a click event on its <ul> in order
    # to focus it.
    focusFirstSecondaryAttributesField: ->
      firstFieldIsTagit =
        @$(@secondaryDataSelector)
          .find('.dative-form-field')
          .filter(':visible')
          .first()
          .find('ul.tagit').length > 0
      if firstFieldIsTagit
        @$(@secondaryDataSelector).find('ul.tagit').first().click()
      else
        super

