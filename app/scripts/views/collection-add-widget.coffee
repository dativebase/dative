define [
  './resource-add-widget'
  './textarea-field'
  './select-field'
  './relational-select-field'
  './script-field'
  './date-field'
  './person-select-field'
  './user-select-field'
  './source-select-field'
  './multi-element-tag-field'
  './source-select-via-search-field'
  './speaker-select-field-with-add-button'
  './user-select-field-with-add-button'
  './../models/collection'
], (ResourceAddWidgetView, TextareaFieldView, SelectFieldView,
  RelationalSelectFieldView, ScriptFieldView, DateFieldView,
  PersonSelectFieldView, UserSelectFieldView, SourceSelectFieldView,
  MultiElementTagFieldView, SourceSelectViaSearchFieldView,
  SpeakerSelectFieldWithAddButtonView, UserSelectFieldWithAddButtonView
  CollectionModel) ->


  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  # A <select>-based field view for the markup language select field.
  class MarkupLanguageFieldView extends SelectFieldView

    initialize: (options) ->
      options.required = true
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) -> o
      super options


  # A <select>-based field view for the markup language select field.
  class CollectionTypeFieldView extends SelectFieldView

    initialize: (options) ->
      options.required = true
      options.selectValueGetter = (o) -> o
      options.selectTextGetter = (o) -> o
      options.optionsAttribute = 'collection_types'
      super options


  class ElicitorSelectFieldWithAddButtonView extends UserSelectFieldWithAddButtonView

    attributeName: 'elicitor'

  # Collection Add Widget View
  # --------------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # collection (i.e., OLD text-like resource) and updating an existing one.

  ##############################################################################
  # Collection Add Widget
  ##############################################################################

  class CollectionAddWidgetView extends ResourceAddWidgetView

    resourceName: 'collection'
    resourceModel: CollectionModel

    attribute2fieldView:
      name:            TextareaFieldView255
      content:         ScriptFieldView
      markup_language: MarkupLanguageFieldView
      type:            CollectionTypeFieldView
      date_elicited:   DateFieldView
      speaker:         SpeakerSelectFieldWithAddButtonView
      elicitor:        ElicitorSelectFieldWithAddButtonView
      source:          SourceSelectViaSearchFieldView
      tags:            MultiElementTagFieldView

    primaryAttributes: [
      'title'
      'description'
      'type'
      'url'
      'markup_language'
      'contents'
    ]

    editableSecondaryAttributes: [
      'source'
      'speaker'
      'elicitor'
      'date_elicited'
      'tags' # Need a better search/autocomplete interface
      # 'files' Need a better search/autocomplete interface
    ]

    # Focus the first visible field view in the secondary attributes section.
    focusFirstSecondaryAttributesField: ->
      @$(@secondaryDataSelector)
        .find('textarea, .ui-selectmenu-button,
          input.resource-select-via-search-input-input')
        .filter(':visible').first().focus()

