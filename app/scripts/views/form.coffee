define [
  'jquery'
  'lodash'
  'backbone'
  'views/base'
], ($, _, Backbone, BaseView) ->

  # Form View
  # ---------
  #
  # For displaying individual forms with an IGT interface.

  class FormView extends BaseView

    template: JST['app/scripts/templates/form.ejs']

    tagName: 'div'

    id: ''

    className: ''

    events: {}

    initialize: () ->
      @listenTo @model, 'change', @render

    render: () ->
      console.log 'render called in FormView'
      @$el.html @template(@model.toJSON())
      this
