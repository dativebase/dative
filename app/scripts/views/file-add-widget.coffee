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

  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  # The typed textarea field view is a textarea field that is visible only when
  # the file is of a certain type, i.e., stored on the web service, hosted
  # elsewhere, or subinterval-referencing.
  class TypedTextareaFieldView extends TextareaFieldView

    listenToEvents: ->
      super
      @listenTo @model, 'change:dative_file_type', @crucialAttributeChanged

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
        @utils.startsWith MIME_type, 'audio' or
        @utils.startsWith MIME_type, 'video'
      else
        # Assuming for now (incorrectly) that anything without a MIME_type is
        # externally hosted audio/video
        true

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


  class SubintervalReferencingFileAttributeFieldView extends TypedTextareaFieldView

    visibilityCondition: ->
      @model.get('dative_file_type') is 'referencesASubintervalOfAnotherFile'


  class FileAsRowView extends ResourceAsRowView

    resourceName: 'file'

    orderedAttributes: [
      'id'
      'filename'
      'MIME_type'
      'size'
      'enterer'
    ]

  class ParentFileSearchInputView extends ResourceSelectViaSearchInputView

    # Change these attributes in subclasses.
    resourceName: 'file'
    resourceModelClass: FileModel
    resourceAsRowViewClass: FileAsRowView
    resourceMediaViewClass: FileData


  class ParentFileSearchFieldView extends ResourceSelectViaSearchFieldView

    getInputView: ->
      new ParentFileSearchInputView @context

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
      name:                          NonLocalFileAttributeFieldView
      utterance_type:                UtteranceTypeSelectFieldView
      parent_file:                   ParentFileSearchFieldView

    # We listen to a `setAttribute` event triggered on our `@model`. We do this
    # because the `ParentFileSearchFieldView` will trigger this when it wants
    # us to set `start` and/or `end` values.
    listenToEvents: ->
      super
      @listenTo @model, 'setAttribute', @setAttribute

    # Valuate the (assumedly) textarea input with `name=attr` to `val`. Useful
    # for letting one field view set the values of another.
    setAttribute: (attr, val) ->
      console.log "in setAttribute with #{attr} and #{val}"
      @$("textarea[name=#{attr}]")
        .val val
        .trigger 'input'

    primaryAttributes: [
      'dative_file_type'
      'file_data'
      'url'
      'name'
      'password'
      'parent_file'
      'start'
      'end'
      'description'
    ]

    editableSecondaryAttributes: [
      'tags'
      'utterance_type'
      'speaker'
      'elicitor'
      'date_elicited'
      #'forms'
    ]

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

