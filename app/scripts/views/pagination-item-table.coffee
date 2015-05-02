define [
  'backbone'
  './base'
  './../templates/pagination-item-table'
], (Backbone, BaseView, paginationItemTableTemplate) ->

  # Pagination Item Table View
  # --------------------------
  #
  # An HTML table to hold the HTML of a resource view. It contains a single row
  # where the first cell contains the index and the second contains the
  # resource view's HTML.

  class PaginationItemTableView extends BaseView

    template: paginationItemTableTemplate
    tagName: 'table'
    className: 'dative-pagin-item'

    initialize: (options) ->
      @resourceId = options.resourceId
      @index = options.index

    render: ->
      context =
        resourceId: @resourceId
        index: @index
        integerWithCommas: @utils.integerWithCommas
      @$el.html @template(context)
      @

