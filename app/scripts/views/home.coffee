define [
  'backbone',
  './base',
  './../templates/home'
], (Backbone, BaseView, homepageTemplate) ->

  # Home Page View
  # --------------

  class HomePageView extends BaseView

    template: homepageTemplate

    render: ->
      @$el.html @template()
      @matchHeights()

