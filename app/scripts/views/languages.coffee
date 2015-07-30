define [
  './resources'
  './language'
  './search-widget'
  './search-field'
  './../collections/languages'
  './../models/language'
  './../models/search'
  './../utils/globals'
], (ResourcesView, LanguageView, SearchWidgetView, SearchFieldView,
  LanguagesCollection, LanguageModel, SearchModel, globals) ->


  class LanguageSearchFieldViewNoLabel extends SearchFieldView

    showLabel: false
    targetResourceName: 'language'


  class LanguageSearchModel extends SearchModel

    # Change the following three attributes if this search model is being used
    # to search over a resource other than forms, e.g., over language resources.
    targetResourceName: 'language'
    targetResourcePrimaryAttribute: 'Id'
    targetResourcePrimaryKey: 'Id'
    targetModelClass: LanguageModel


  class LanguageSearchWidgetView extends SearchWidgetView

    targetResourceName: 'language'
    targetModelClass: LanguageModel
    searchModelClass: LanguageSearchModel
    searchFieldViewClass: LanguageSearchFieldViewNoLabel


  # Languages View
  # --------------
  #
  # Displays a collection of languages for browsing, with pagination. Also
  # contains a model-less `LanguageView` instance for creating new languages
  # within the browse interface.
  #
  # Note: the languages resource is read-only. It's just the ISO 639-3
  # Ethnologue language data and is a convenience.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class LanguagesView extends ResourcesView

    resourceName: 'language'
    resourceView: LanguageView
    resourcesCollection: LanguagesCollection
    resourceModel: LanguageModel
    searchable: true
    searchView: LanguageSearchWidgetView
    searchModel: LanguageSearchModel

    # New languages cannot be created. (Change this?)
    getCanCreateNew: -> false

