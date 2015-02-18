define [
  'backbone',
  './base',
  './../templates/forms-search'
], (Backbone, BaseView, formsSearchTemplate) ->

  # Search Forms View
  # --------------

  class FormsSearchView extends BaseView

    template: formsSearchTemplate

    render: (taskId) ->
      @$el.html @template()
      @matchHeights()
      @fixRoundedBorders()
      Backbone.trigger 'longTask:deregister', taskId
      @

