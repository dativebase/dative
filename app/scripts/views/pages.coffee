define [
  './resources'
  './page'
  './../collections/pages'
  './../models/page'
  './../utils/globals'
], (ResourcesView, PageView, PagesCollection,
  PageModel, globals) ->

  # Pages View
  # ---------
  #
  # Displays a collection of pages for browsing, with pagination. Also contains
  # a model-less `PageView` instance for creating new pages within
  # the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class PagesView extends ResourcesView

    resourceName: 'page'
    resourceView: PageView
    resourcesCollection: PagesCollection
    resourceModel: PageModel

