define [
  'backbone'
  './base'
  './../templates/pagination-menu-top'
], (Backbone, BaseView, template) ->

  # Pagination Menu Top View
  # ------------------------
  #
  # View for buttons and controls that allow for the navigation of a
  # paginated collection, e.g., first page, next page, page 6, etc.

  class PaginationMenuTopView extends BaseView

    template: template
    tagName: 'div'
    className: 'dative-pagination-menu-top'

    initialize: (options) ->
      @pagination = @defaultPagination
      @pagination = @getPagination options

    events: {}

    defaultPagination:
      items: 0
      itemsPerPage: 10
      possibleItemsPerPage: [1, 5, 10, 25, 50, 100]
      page: 1
      pages: 0

    getPagination: (options) ->
      try
        pagination = options.pagination
        _.extend @defaultPagination, pagination
      catch
        @pagination

    pluralize: (numeral) ->
      switch numeral
        when 1 then ''
        else 's'

    getContext: ->
      _.extend {pluralize: @pluralize}, @pagination

    render: (options) ->
      @pagination = @getPagination options
      console.log 'in render of pagination menu'
      console.log @pagination
      #@$el.html @template(@pagination)
      @$el.html @template(@getContext())
      @guify()
      @buttonVisibility()
      @

    guify: ->

      @$('button.first-page')
        .button()
        .tooltip
          position:
            my: "right-10 center"
            at: "left center"
            collision: "flipfit"

      @$('button.previous-page')
        .button()
        .tooltip
          position:
            my: "right-45 center"
            at: "left center"
            collision: "flipfit"

      @$('button.next-page')
        .button()
        .tooltip
          position:
            my: "left+45 center"
            at: "right center"
            collision: "flipfit"

      @$('button.last-page')
        .button()
        .tooltip
          position:
            my: "left+10 center"
            at: "right center"
            collision: "flipfit"

      @$('button.current-minus-3')
        .button()
        .tooltip
          position:
            my: "left+10 center"
            at: "right center"
            collision: "flipfit"

      @$('button.current-minus-2')
        .button()
        .tooltip
          position:
            my: "left+10 center"
            at: "right center"
            collision: "flipfit"

      @$('button.current-minus-1')
        .button()
        .tooltip
          position:
            my: "left+10 center"
            at: "right center"
            collision: "flipfit"

      @$('button.current-page')
        .button()
        .tooltip
          position:
            my: "left+10 center"
            at: "right center"
            collision: "flipfit"

      @$('button.current-plus-1')
        .button()
        .tooltip
          position:
            my: "left+10 center"
            at: "right center"
            collision: "flipfit"

      @$('button.current-plus-2')
        .button()
        .tooltip
          position:
            my: "left+10 center"
            at: "right center"
            collision: "flipfit"

      @$('button.current-plus-3')
        .button()
        .tooltip
          position:
            my: "left+10 center"
            at: "right center"
            collision: "flipfit"

      @$('select').selectmenu width: 200
        .next('.ui-selectmenu-button').addClass('items-per-page')

      @$('.ui-selectmenu-button').filter('.items-per-page')
        .addClass 'dative-tooltip'
        .tooltip
          items: 'span'
          content: 'how many items to display per page'
          position:
            my: "right-10 center"
            at: "left center"
            collision: "flipfit"

    buttonVisibility: ->
      @$('.current-page')
        .button 'option', 'label', @pagination.page
        .button 'disable'
      pageNumbers =
        '.current-minus-3': @pagination.page - 3
        '.current-minus-2': @pagination.page - 2
        '.current-minus-1': @pagination.page - 1
        '.current-plus-1': @pagination.page + 1
        '.current-plus-2': @pagination.page + 2
        '.current-plus-3': @pagination.page + 3
      for selector, pageNumber of pageNumbers
        if pageNumber > @pagination.pages or pageNumber < 1
          @$(selector)
            .button 'disable'
            .hide()
          console.log "#{selector} should be hidden"
        else
          console.log "#{selector} should have value #{pageNumber}"
          @$(selector)
            .button 'option', 'label', pageNumber
            .button 'enable'
            .tooltip
              content: "Go to page #{pageNumber}"
              position:
                my: 'left top'
                at: 'left bottom+10'
                collision: 'flipfit'
            .show()

