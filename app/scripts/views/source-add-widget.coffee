define [
  './resource-add-widget'
  './textarea-field'
  './select-field'
  './relational-select-field'
  './../models/source'
], (ResourceAddWidgetView, TextareaFieldView, SelectFieldView,
  RelationalSelectFieldView, SourceModel) ->


  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  class TextareaFieldView1000 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 1000
      super options


  class TextareaFieldView100 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 100
      super options


  # A <select>-based field view for the source's (BibTeX) type.
  class TypeSelectFieldView extends SelectFieldView

    initialize: (options) ->
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) -> o
      options.required = true
      super options


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
      key: TextareaFieldView1000
      address: TextareaFieldView1000
      note: TextareaFieldView1000
      url: TextareaFieldView1000

      author: TextareaFieldView255
      booktitle: TextareaFieldView255
      chapter: TextareaFieldView255
      edition: TextareaFieldView255
      editor: TextareaFieldView255
      howpublished: TextareaFieldView255
      institution: TextareaFieldView255
      journal: TextareaFieldView255
      key_field: TextareaFieldView255
      organization: TextareaFieldView255
      publisher: TextareaFieldView255
      school: TextareaFieldView255
      series: TextareaFieldView255
      title: TextareaFieldView255
      type_field: TextareaFieldView255

      month: TextareaFieldView100
      number: TextareaFieldView100
      pages: TextareaFieldView100
      volume: TextareaFieldView100

      type: TypeSelectFieldView
      # file: FileSearchFieldView # Note: does not work yet; see TODO above.

    primaryAttributes: [
      'key'
      'type'
      'file'
      'crossref' # TODO: this should have a field view that is a search UI (over sources), just like that for `file`
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

