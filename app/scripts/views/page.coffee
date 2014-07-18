define [
    'jquery',
    'lodash',
    'backbone'
  ], ($, _, Backbone) ->

    # Page Item View
    # --------------

    class PageView extends Backbone.View
      tagName:  'div'

      # Cache the template function for a single item.
      template: JST['app/scripts/templates/page.ejs']

      initialize: ->
        @model.on 'change', @render, @
        @model.on 'destroy', @remove, @

      render: ->
        @$el.html @template(@model.toJSON())
        @
