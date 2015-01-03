define [
  'backbone',
  './base',
  './../templates/forms-search'
], (Backbone, BaseView, formsSearchTemplate) ->

  # Search Forms View
  # --------------

  class FormsSearchView extends BaseView

    template: formsSearchTemplate

    render: ->
      @$el.html @template()
      @matchHeights()

