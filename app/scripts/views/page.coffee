define [
    'backbone'
    './../templates/page'
  ], (Backbone, pageTemplate) ->

    # Page Item View
    # --------------

    class PageView extends Backbone.View
      tagName:  'div'

      # Cache the template function for a single item.
      template: pageTemplate

      initialize: ->
        @model.on 'change', @render, @
        @model.on 'destroy', @remove, @

      render: ->
        @$el.html @template(@model.toJSON())
        this
