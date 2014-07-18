define [
  'jquery',
  'lodash',
  'backbone',
  'collections/pages',
  'views/basepage',
  'views/page'
], ($, _, Backbone, pagesCollection, BasePageView, PageView) ->

  # Pages View
  # --------------

  # The DOM element for summarizing the pages of an OLD app
  class PagesView extends BasePageView

    pagesCollection: pagesCollection

    initialize: ->
      @initialized = true
      @pagesCollection.on 'reset', @render, @
      @pagesCollection.fetch()

    render: ->
      @$el.html @template(headerTitle: 'Pages')
      @matchHeights()
      @addAll()

    # Append a single page item to the #old-page-body div of the pages view.
    addOne: (pageModel) ->
      pageView = new PageView(model: pageModel)
      $('#old-page-body').append pageView.render().el

    # Add all items in **pagesCollection** at once.
    addAll: ->
      @$('#old-page-body').empty()
      @pagesCollection.each @addOne, @

