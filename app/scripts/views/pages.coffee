define [
  'backbone',
  './base',
  './page'
  './../collections/pages',
  './../templates/basepage'
], (Backbone, BaseView, PageView, PagesCollection, basepageTemplate) ->

  # Pages View
  # --------------

  # The DOM element for summarizing the pages of a Dative app
  class PagesView extends BaseView

    template: basepageTemplate

    pagesCollection: PagesCollection

    initialize: ->
      @initialized = true
      @pagesCollection.on 'reset', @render, @
      #@pagesCollection.fetch()

    render: (taskId) ->
      @$el.html @template(headerTitle: 'Pages')
      @matchHeights()
      @addAll()
      @fixRoundedBorders()
      Backbone.trigger 'longTask:deregister', taskId
      @

    # Append a single page item to the #dative-page-body div of the pages view.
    addOne: (pageModel) ->
      pageView = new PageView(model: pageModel)
      @$('#dative-page-body').append pageView.render().el

    # Add all items in **pagesCollection** at once.
    addAll: ->
      @$('#dative-page-body').empty()
      @pagesCollection.each @addOne, @

