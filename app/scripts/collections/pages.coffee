define [
  './resources'
  './../models/page'
], (ResourcesCollection, PageModel) ->

  # Pages Collection
  # ----------------
  #
  # Holds models for pages.

  class PagesCollection extends ResourcesCollection

    resourceName: 'page'
    model: PageModel

