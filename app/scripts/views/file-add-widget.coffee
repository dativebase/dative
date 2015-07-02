define [
  './resource-add-widget'
  './textarea-field'
  './relational-select-field'
  './multiselect-field'
  './person-select-field'
  './user-select-field'
  './date-field'
  './file-data-upload-field'
  './select-field'
  './../models/file'
], (ResourceAddWidgetView, TextareaFieldView, RelationalSelectFieldView,
  MultiselectFieldView, PersonSelectFieldView, UserSelectFieldView,
  DateFieldView, FileDataUploadFieldView, SelectFieldView, FileModel) ->




  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


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

    hideAnimate: ->
      if @$el.is ':visible'
        @$el.slideUp()

    showAnimate: ->
      if not @$el.is(':visible')
        @$el.slideDown()

    isAudioVideo: ->
      MIME_type = @model.get 'MIME_type'
      @utils.startsWith MIME_type, 'audio' or
      @utils.startsWith MIME_type, 'video'


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

    render: ->
      super
      @

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
      filename:                      FilenameFieldView
      parent_file:                   SubintervalReferencingFileAttributeFieldView
      start:                         SubintervalReferencingFileAttributeFieldView
      end:                           SubintervalReferencingFileAttributeFieldView
      url:                           NonLocalFileAttributeFieldView
      password:                      NonLocalFileAttributeFieldView
      utterance_type:                UtteranceTypeSelectFieldView

    primaryAttributes: [
      'dative_file_type'
      'file_data'
      'url'
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

