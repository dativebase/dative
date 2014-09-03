define [
    'lodash',
    'backbone',
    './../models/page'
  ], (_, Backbone, PageModel) ->

    class PagesCollection extends Backbone.Collection
      # Reference to this collection's model.
      model: PageModel
      url: '/pages'
    return new PagesCollection()

