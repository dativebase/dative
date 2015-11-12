define [
  './resources'
  './form'
  './search'
  './search-add-widget'
  './search-widget'
  './csv-import'
  './../collections/forms'
  './../models/form'
  './../models/search'
], (ResourcesView, FormView, SearchView, SearchAddWidgetView, SearchWidgetView,
  CSVImportView, FormsCollection, FormModel, SearchModel) ->

  class SearchAddWidgetSearchEmphasizedView extends SearchAddWidgetView

    primaryAttributes: [
      'search'
    ]

    editableSecondaryAttributes: [
      'name'
      'description'
    ]

  class SearchViewSearchEmphasizedView extends SearchView

    resourceAddWidgetView: SearchAddWidgetSearchEmphasizedView

    # Attributes that are always displayed.
    primaryAttributes: [
      'search'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'name'
      'description'
      'enterer'
      'datetime_modified'
      'id'
    ]

  # Forms View
  # ----------
  #
  # Displays a collection of forms for browsing, with pagination. Also
  # contains a model-less FormView instance for creating new forms
  # within the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class FormsView extends ResourcesView

    resourceName: 'form'
    resourceView: FormView
    resourcesCollection: FormsCollection
    resourceModel: FormModel

    initialize: (options) ->
      # Put "(1)", "(2)", etc. before form resource representations.
      options.enumerateResources = true
      super options

    searchable: true

    searchViewClass: SearchWidgetView
    searchModelClass: SearchModel

    importable: true

    importViewClass: CSVImportView

