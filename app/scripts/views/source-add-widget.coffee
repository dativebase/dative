define [
  './resource-add-widget'
  './textarea-field'
  './select-field'
  './relational-select-field'
  './resource-select-via-search-field'
  './resource-select-via-search-input'
  './resource-as-row'
  './file-data'
  './../models/source'
  './../models/file'
], (ResourceAddWidgetView, TextareaFieldView, SelectFieldView,
  RelationalSelectFieldView, ResourceSelectViaSearchFieldView,
  ResourceSelectViaSearchInputView, ResourceAsRowView, FileData, SourceModel,
  FileModel) ->


  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  # A <select>-based field view for the source's (BibTeX) type.
  class TypeSelectFieldView extends SelectFieldView

    initialize: (options) ->
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) -> o
      options.required = true
      super options


  ##############################################################################
  # These classes are used to build the field view for searching files for a
  # source's file.
  ##############################################################################

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


  class FileSearchInputView extends ResourceSelectViaSearchInputView

    # Change these attributes in subclasses.
    resourceName: 'file'
    resourceModelClass: FileModel
    resourceAsRowViewClass: FileAsRowView
    resourceMediaViewClass: FileData


  # TODO: this will not work as a field (search) view for the `file` attribute
  # of sources. This is because the `ResourceSelectViaSearchInput` class
  # assumes at a fundamental level that the resource being searched over as
  # well as the "root" resource are both files, whereas in this case the "root"
  # resource is a source resource. That class must be rewritten; in particular,
  # its `performSearch` method should not be triggering methods on `@model` but
  # on some instance of `@resourceModelClass`.
  class FileSearchFieldView extends ResourceSelectViaSearchFieldView

    getInputView: ->
      new FileSearchInputView @context

    listenToEvents: ->
      super
      if @inputView
        @listenTo @inputView, 'validateMe', @myValidate

    myValidate: ->
      if @submitAttempted then @validate()



  # Source Add Widget View
  # ----------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # source and updating an existing one.

  ##############################################################################
  # Source Add Widget
  ##############################################################################

  class SourceAddWidgetView extends ResourceAddWidgetView

    resourceName: 'source'
    resourceModel: SourceModel

    attribute2fieldView:
      type: TypeSelectFieldView
      file: FileSearchFieldView # Note: does not work yet; see TODO above.

    primaryAttributes: [
      'key'
      'type'
      'file'
      'crossref_source'
      'crossref'
      'author'
      'editor'
      'year'
      'journal'
      'title'
      'booktitle'
      'chapter'
      'pages'
      'publisher'
      'school'
      'institution'
      'note'
    ]

    editableSecondaryAttributes: [
      'volume'
      'number'
      'month'
      'series'
      'address'
      'edition'
      'annote'
      'howpublished'
      'key_field'
      'organization'
      'type_field'
      'url'
      'affiliation'
      'abstract'
      'contents'
      'copyright'
      'ISBN'
      'ISSN'
      'keywords'
      'language'
      'location'
      'LCCN'
      'mrnumber'
      'price'
      'size'
    ]

