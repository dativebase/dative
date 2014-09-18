define [
  'jquery',
  'lodash',
  'backbone',
  './../collections/pages',
  './base',
  './page'
], ($, _, Backbone, pagesCollection, BaseView, PageView) ->

  # Pages View
  # --------------

  # The DOM element for summarizing the pages of a Dative app
  class PagesView extends BaseView

    template: JST['app/scripts/templates/basepage.ejs']

    pagesCollection: pagesCollection

    initialize: ->
      @initialized = true
      @pagesCollection.on 'reset', @render, @
      #@pagesCollection.fetch()

    render: ->
      @$el.html @template(headerTitle: 'Pages')
      @matchHeights()
      @addAll()

    # Append a single page item to the #dative-page-body div of the pages view.
    addOne: (pageModel) ->
      pageView = new PageView(model: pageModel)
      @$('#dative-page-body').append pageView.render().el

    # Add all items in **pagesCollection** at once.
    addAll: ->
      @$('#dative-page-body').empty()
      @pagesCollection.each @addOne, @

