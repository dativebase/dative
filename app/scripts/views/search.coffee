define [
  './resource'
  './search-controls'
  './search-add-widget'
  './person-field-display'
  './date-field-display'
  './object-with-name-field-display'
  './array-of-objects-with-name-field-display'
  './query-field-display'
], (ResourceView, SearchControlsView, SearchAddWidgetView,
  PersonFieldDisplayView, DateFieldDisplayView, ObjectWithNameFieldDisplayView,
  ArrayOfObjectsWithNameFieldDisplayView, QueryFieldDisplayView) ->

  # Search View
  # --------------
  #
  # For displaying individual searches.

  class SearchView extends ResourceView

    resourceName: 'search'

    resourceAddWidgetView: SearchAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: [
      'name'
      'description'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'search'
      'enterer'
      'datetime_modified'
      'id'
    ]

    attribute2displayView:
      enterer: PersonFieldDisplayView
      datetime_modified: DateFieldDisplayView
      search: QueryFieldDisplayView

    excludedActions: ['history']

    controlsViewClass: SearchControlsView

    showControlsWithNew: true

