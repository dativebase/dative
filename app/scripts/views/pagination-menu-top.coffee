define [
  'backbone'
  './base'
  './../utils/paginator'
  './../templates/pagination-menu-top'
], (Backbone, BaseView, Paginator, template) ->

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
      @paginator = @defaultPaginator
      @paginator = @getPaginator options

    events:
      'selectmenuchange': 'changeItemsPerPage'

      'click .first-page': 'showFirstPage'
      'click .last-page': 'showLastPage'
      'click .previous-page': 'showPreviousPage'
      'click .next-page': 'showNextPage'

      'click .current-minus-3': 'showThreePagesBack'
      'click .current-minus-2': 'showTwoPagesBack'
      'click .current-minus-1': 'showOnePageBack'

      'click .current-plus-1': 'showOnePageForward'
      'click .current-plus-2': 'showTwoPagesForward'
      'click .current-plus-3': 'showThreePagesForward'

    # A paginator is an object with data and logic about pagination, i.e.,
    # how many items are being shown?, how many are there?, which page?, etc.
    defaultPaginator: ->
      new Paginator()

    getPaginator: (options) ->
      try
        paginator = options.paginator
      catch
        paginator = @paginator
      paginator

    getContext: ->
      _.extend {pluralizeByNum: @utils.pluralizeByNum}, @paginator

    render: (options) ->
      @paginator = @getPaginator options
      @$el.html @template(@getContext())
      @guify()
      @setButtonState()
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

      # specify selected option of itemsPerPage select
      @$('select[name=items-per-page] option').each (index, element) =>
        $option = $(element)
        if Number($option.val()) is @paginator.itemsPerPage
          $option.prop 'selected', true
        else
          $option.prop 'selected', false

      @$('select').selectmenu width: 160
        .next('.ui-selectmenu-button').addClass('items-per-page')

      # SMALL BUG: tooltip seems to be generated on two elements by the following:
      @$('.ui-selectmenu-button').filter('.items-per-page')
        .addClass 'dative-tooltip'
        .tooltip
          items: 'span'
          content: 'how many items to display per page'
          position:
            my: "right-10 center"
            at: "left center"
            collision: "flipfit"

    # Enable/disable pagination buttons (and potentially set their values, e.g.,
    # to page numbers, and potentially hide them too).
    setButtonState: ->
      @setCurrentPageButtonState()
      @setNumberedPageButtonsState()
      @setPreviousFirstPageButtonsState()
      @setNextLastPageButtonsState()

    # The current page button is unique: always disabled.
    setCurrentPageButtonState: ->
      @$('.current-page')
        .button 'option', 'label', @paginator.page
        .button 'disable'

    # Set the state of the 6 page-numbered buttons that surround the current
    # page button.
    setNumberedPageButtonsState: ->
      pageNumbers =
        '.current-minus-3': @paginator.page - 3
        '.current-minus-2': @paginator.page - 2
        '.current-minus-1': @paginator.page - 1
        '.current-plus-1': @paginator.page + 1
        '.current-plus-2': @paginator.page + 2
        '.current-plus-3': @paginator.page + 3
      for selector, pageNumber of pageNumbers
        if pageNumber > @paginator.pages or pageNumber < 1
          @$(selector)
            .button 'disable'
            .hide()
        else
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

    setPreviousFirstPageButtonsState: ->
      if @paginator.page is 1
        @$('.previous-page, .first-page').button 'disable'
      else
        @$('.previous-page, .first-page').button 'enable'

    setNextLastPageButtonsState: ->
      if @paginator.page is @paginator.pages
        @$('.next-page, .last-page').button 'disable'
      else
        @$('.next-page, .last-page').button 'enable'

    ############################################################################
    # Methods that trigger events requesting for specific pages to be shown.
    ############################################################################

    changeItemsPerPage: ->
      newItemsPerPage = Number @$('select[name=items-per-page]').val()
      if isNaN newItemsPerPage
        newItemsPerPage = 10
      @trigger 'paginator:changeItemsPerPage', newItemsPerPage

    showFirstPage: ->
      @trigger 'paginator:showFirstPage'

    showLastPage: ->
      @trigger 'paginator:showLastPage'

    showPreviousPage: ->
      @trigger 'paginator:showPreviousPage'

    showNextPage: ->
      @trigger 'paginator:showNextPage'

    showThreePagesBack: ->
      @trigger 'paginator:showThreePagesBack'

    showTwoPagesBack: ->
      @trigger 'paginator:showTwoPagesBack'

    showOnePageBack: ->
      @trigger 'paginator:showOnePageBack'

    showOnePageForward: ->
      @trigger 'paginator:showOnePageForward'

    showTwoPagesForward: ->
      @trigger 'paginator:showTwoPagesForward'

    showThreePagesForward: ->
      @trigger 'paginator:showThreePagesForward'

