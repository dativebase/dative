define [
  'backbone'
  './base'
  './../templates/pagination-item-table'
], (Backbone, BaseView, paginationItemTableTemplate) ->

  # Pagination Item Table View
  # --------------------------
  #
  # An HTML table to hold the HTML of a form view. It contains a single row where
  # the first cell contains the index and the second contains the form view's HTML.

  class PaginationItemTableView extends BaseView

    template: paginationItemTableTemplate
    tagName: 'table'
    className: 'dative-pagin-item'

    initialize: (options) ->
      @formId = options.formId
      @index = options.index

    render: ->
      context =
        formId: @formId
        index: @index
        integerWithCommas: @utils.integerWithCommas
      @$el.html @template(context)
      @

