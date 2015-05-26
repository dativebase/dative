define [
  './resource-add-widget'
  './textarea-field'
  './search-field'
  './../models/search'
], (ResourceAddWidgetView, TextareaFieldView, SearchFieldView, SearchModel) ->


  class TextareaFieldView255 extends TextareaFieldView

    initialize: (options) ->
      options.domAttributes =
        maxlength: 255
      super options


  # Search Add Widget View
  # --------------------------
  #
  # View for a widget containing inputs and controls for creating a new
  # search and updating an existing one.

  ##############################################################################
  # Search Add Widget
  ##############################################################################

  class SearchAddWidgetView extends ResourceAddWidgetView

    resourceName: 'search'
    resourceModel: SearchModel

    # Maps attributes to their appropriate FieldView subclasses.
    # This is where field-specific configuration should go.
    attribute2fieldView:
      name:        TextareaFieldView255
      search:      SearchFieldView

    primaryAttributes: [
      'name'
      'description'
      'search'
    ]

    editableSecondaryAttributes: []

