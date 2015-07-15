define [
  './resource-add-widget'
  './textarea-field'
  './relational-select-field'
  './multiselect-field'
  './person-select-field'
  './user-select-field'
  './date-field'
  './file-data-upload-field'
  './file-data'
  './select-field'
  './resource-select-via-search-field'
  './resource-select-via-search-input'
  './resource-as-row'
  './../models/file'
], (ResourceAddWidgetView, TextareaFieldView,
  RelationalSelectFieldView, MultiselectFieldView, PersonSelectFieldView,
  UserSelectFieldView, DateFieldView, FileDataUploadFieldView, FileData,
  SelectFieldView, ResourceSelectViaSearchFieldView,
  ResourceSelectViaSearchInputView, ResourceAsRowView, FileModel) ->


  # The typed textarea field view is a textarea field that is visible only when
  # the file is of a certain type, i.e., stored on the web service, hosted
  # elsewhere, or subinterval-referencing.
  class TypedTextareaFieldView extends TextareaFieldView

    listenToEvents: ->
      super
      @listenTo @model, 'change:dative_file_type', @crucialAttributeChanged
      @listenTo @model, 'change:MIME_type', @crucialAttributeChanged

    render: ->
      super
      if not @visibilityCondition() then @$el.hide()
      @

    crucialAttributeChanged: ->
      if @visibilityCondition() then @showAnimate() else @hideAnimate()

    visibilityCondition: ->
      @model.get('dative_file_type') is 'storedOnTheServer'

    hideAnimate: -> if @$el.is ':visible' then @$el.slideUp()

    showAnimate: -> if not @$el.is(':visible') then @$el.slideDown()

    isAudioVideo: ->
      MIME_type = @model.get 'MIME_type'
      if MIME_type
        @utils.startsWith(MIME_type, 'audio') or
        @utils.startsWith(MIME_type, 'video')
      else
        try
          if @model.get('url')
            MIME_type = @utils.getMIMEType @model.get('url')
            @utils.startsWith(MIME_type, 'audio') or
            @utils.startsWith(MIME_type, 'video')
          else
            false
        catch
          false

  # A <select>-based field view for the file's utterance type. We mixin methods
  # from `TypedTextareaFieldView` so that this field will only be visible when
  # the file is audio or video.
  class UtteranceTypeSelectFieldView extends SelectFieldView

    initialize: (options) ->
      @mixin()
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) -> o
      super options

    listenToEvents: ->
      super
      @listenTo @model, 'change:MIME_type', @crucialAttributeChanged

    mixin: ->
      methodsWeWant = [
        'hideAnimate'
        'showAnimate'
        'render'
        'crucialAttributeChanged'
        'isAudioVideo'
      ]
      for method in methodsWeWant
        @[method] = TypedTextareaFieldView::[method]

    visibilityCondition: -> @isAudioVideo()


  # A <select>-based field view for the file's elicitor. This is only displayed
  # when the file is audio or video.
  class ElicitorSelectFieldView extends UserSelectFieldView

    initialize: (options) ->
      @mixin()
      super options

    listenToEvents: ->
      super
      @listenTo @model, 'change:MIME_type', @crucialAttributeChanged

    mixin: ->
      methodsWeWant = [
        'hideAnimate'
        'showAnimate'
        'render'
        'crucialAttributeChanged'
        'isAudioVideo'
      ]
      for method in methodsWeWant
        @[method] = TypedTextareaFieldView::[method]

    visibilityCondition: -> @isAudioVideo()


  # A <select>-based field view for the file's speaker. This is only displayed
  # when the file is audio or video.
  class SpeakerSelectFieldView extends PersonSelectFieldView

    initialize: (options) ->
      @mixin()
      super options

    listenToEvents: ->
      super
      @listenTo @model, 'change:MIME_type', @crucialAttributeChanged

    mixin: ->
      methodsWeWant = [
        'hideAnimate'
        'showAnimate'
        'render'
        'crucialAttributeChanged'
        'isAudioVideo'
      ]
      for method in methodsWeWant
        @[method] = TypedTextareaFieldView::[method]

    visibilityCondition: -> @isAudioVideo()


  # A <select>-based field view for the Dative file type, i.e.,
  # `storedOnTheServer`, `storedOnAnotherServer`, or
  # `referencesASubintervalOfAnotherFile`. Note: this field view is only
  # visible when we are adding/creating a new file; it is not visible on
  # update.
  class DativeFileTypeFieldView extends SelectFieldView

    initialize: (options) ->
      @mixin()
      options.required = true
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) =>
        @utils.camel2regular o
      super options

    mixin: ->
      methodsWeWant = [
        'listenToEvents'
        'crucialAttributeChanged'
        'hideAnimate'
        'showAnimate'
        'render'
      ]
      for method in methodsWeWant
        @[method] = TypedTextareaFieldView::[method]

    visibilityCondition: -> @addUpdateType is 'add'


  class FilenameFieldView extends TypedTextareaFieldView

    listenToEvents: ->
      super
      @listenTo @model, 'change:filename', @filenameChanged

    filenameChanged: ->
      @$("textarea.#{@context.class}").val @model.get('filename')


  class NonLocalFileAttributeFieldView extends TypedTextareaFieldView

    visibilityCondition: ->
      @model.get('dative_file_type') is 'storedOnAnotherServer'

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  class NonLocalOrSubintervalFileAttributeFieldView extends TypedTextareaFieldView

    visibilityCondition: ->
      @model.get('dative_file_type') in ['storedOnAnotherServer',
        'referencesASubintervalOfAnotherFile']

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  class SubintervalReferencingFileAttributeFieldView extends TypedTextareaFieldView

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


  class FileAsRowView extends ResourceAsRowView

    resourceName: 'file'

    orderedAttributes: [
      'id'
      'filename'
      'MIME_type'
      'size'
      'enterer'
      'tags'
      'forms'
    ]


  class ParentFileData extends FileData

    initialize: (options) ->
      options.parentFile = true
      super options


  class ParentFileSearchInputView extends ResourceSelectViaSearchInputView

    # Change these attributes in subclasses.
    resourceName: 'file'
    resourceModelClass: FileModel
    resourceAsRowViewClass: FileAsRowView
    resourceMediaViewClass: ParentFileData


  class ParentFileSearchFieldView extends ResourceSelectViaSearchFieldView

    getInputView: ->
      new ParentFileSearchInputView @context

    initialize: (options) ->
      @mixin()
      super options

    listenToEvents: ->
      super
      @listenTo @model, 'change:dative_file_type', @crucialAttributeChanged
      if @inputView
        @listenTo @inputView, 'validateMe', @myValidate

    myValidate: ->
      if @submitAttempted then @validate()

    mixin: ->
      methodsWeWant = [
        'crucialAttributeChanged'
        'hideAnimate'
        'showAnimate'
        'render'
      ]
      for method in methodsWeWant
        @[method] = TypedTextareaFieldView::[method]

    visibilityCondition: ->
      @model.get('dative_file_type') is 'referencesASubintervalOfAnotherFile'


  class TypedFileDataUploadFieldView extends FileDataUploadFieldView

    initialize: (options) ->
      @mixin()
      super options

    mixin: ->
      methodsWeWant = [
        'listenToEvents'
        'crucialAttributeChanged'
        'hideAnimate'
        'showAnimate'
        'render'
      ]
      for method in methodsWeWant
        @[method] = TypedTextareaFieldView::[method]

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
      tags:                          MultiselectFieldView
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

