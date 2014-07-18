define [
  'jquery',
  'lodash',
  'backbone',
  'views/basepage'
], ($, _, Backbone, BasePageView) ->

  # Form Add View
  # --------------

  # The DOM element for adding a new form
  class FormAddView extends BasePageView

    initialize: ->
      @initialized = true

    render: ->
      @$el.html @template(headerTitle: 'Add a Form')
      @matchHeights()

