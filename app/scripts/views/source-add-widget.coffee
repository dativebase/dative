define [
  './resource-add-widget'
  './textarea-field'
  './select-field'
  './relational-select-field'
  './related-resource-representation'
  './file-select-via-search-field'
  './source-select-via-search-field'
  './source-select-via-search-input'
  './../models/source'
], (ResourceAddWidgetView, TextareaFieldView, SelectFieldView,
  RelationalSelectFieldView, RelatedResourceRepresentationView,
  FileSelectViaSearchFieldView, SourceSelectViaSearchFieldView,
  SourceSelectViaSearchInputView, SourceModel, ResourceAsRowView) ->


  # The `crossref` and `crossref_source` attributes are interlinked in Source
  # models in a complex way. To choose a `crossref` value, the user must select
  # from the existing sources. This valuates two things:
  #
  # 1. `crossref` as the selected source's `key` value
  # 2. `crossref_source` as the selected source (an object)
  #
  # This fact is what requires us to define
  # `CrossrefSourceSelectViaSearchFieldView` and its dependent classes with
  # some rather ad hoc methods below.

  class MyRelatedResourceRepresentationView extends RelatedResourceRepresentationView

    getRelatedResourceId: ->
      @context.model.get('crossref_source').id


  class CrossrefSourceSelectViaSearchInputView extends SourceSelectViaSearchInputView

    # This is the class that is used to display the *selected* resource.
    selectedResourceViewClass: MyRelatedResourceRepresentationView

    resourceAsString: (resource) -> resource.key

    setSelectedToModel: (resourceAsRowView) ->
      @model.set 'crossref', resourceAsRowView.model.get('key')
      @model.set 'crossref_source', resourceAsRowView.model.attributes

    unsetSelectedFromModel: ->
      @model.set 'crossref_source', null
      @model.set 'crossref', ''

    getSelectedResourceView: ->
      params =
        value: @selectedResourceModel.attributes
        class: 'field-display-link dative-tooltip'
        resourceAsString: @resourceAsString
        valueFormatter: (v) -> v
        resourceName: @resourceName
        attributeName: @context.attribute
        resourceModelClass: @resourceModelClass
        resourcesCollectionClass: @resourcesCollectionClass
        resourceViewClass: null
        model: @getModelForSelectedResourceView()
      if @selectedResourceWrapperViewClass
        new @selectedResourceWrapperViewClass @selectedResourceViewClass, params
      else
        new @selectedResourceViewClass params

    # If we have a selected value, cause it to be displayed and the search
    # interface to not be displayed; if not, do the opposite.
    setStateBasedOnSelectedValue: ->
      if @context.value
        attributes = @context.model.get('crossref_source')
        @selectedResourceModel = new @resourceModelClass(attributes)
        @searchInterfaceVisible = false
        @selectedResourceViewVisible = true
      else
        @searchInterfaceVisible = true
        @selectedResourceViewVisible = false


  class CrossrefSourceSelectViaSearchFieldView extends SourceSelectViaSearchFieldView

    getInputView: ->
      new CrossrefSourceSelectViaSearchInputView @context


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
      file: FileSelectViaSearchFieldView
      crossref: CrossrefSourceSelectViaSearchFieldView

    primaryAttributes: [
      'key'
      'type'
      'file'
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

