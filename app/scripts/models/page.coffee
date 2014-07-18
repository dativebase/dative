define [
    'lodash',
    'backbone',
  ], (_, Backbone) ->

    # Page Model
    # ----------

    class PageModel extends Backbone.Model

      urlRoot: '/pages'

      # Listing of the attributes of a page (for reference).
      attributesMap:
        id: undefined                           # int
        name: undefined                         # max 255
        content: undefined                      # text
        heading: undefined                      # max 255
        markup: undefined                       # max 255
        datetimeModified: undefined             # datetime, default is now

