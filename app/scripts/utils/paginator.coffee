define [], ->

  # Paginator
  # ---------
  #
  # Holds a integers and logic for manipulating pagination.

  class Paginator

    constructor: ->
      # user-settable attributes
      @items = 0
      @itemsPerPage = 10
      @page = 1

      # computed attributes
      @itemsDisplayed = 0
      @pages = 0
      @start = 0
      @end = 0

    # Public methods

    setItems: (newItems) ->
      @items = newItems
      @_refresh()

    setItemsPerPage: (newItemsPerPage) ->
      @itemsPerPage = newItemsPerPage
      @_refresh()

    setPage: (newPage) ->
      @page = newPage
      @_refresh()

    # Private methods

    _refresh: ->
      @_setStart()
      @_setEnd()
      @_setPages()
      @_setItemsDisplayed()

    _setStart: ->
      @start = (@page - 1) * @itemsPerPage

    _setEnd: ->
      @end = @start + @itemsPerPage - 1

    _setPages: ->
      @pages = Math.ceil(@items / @itemsPerPage)

    _setItemsDisplayed: ->
      if @itemsPerPage > @items
        @itemsDisplayed = @items
      else
        @itemsDisplayed = @itemsPerPage


