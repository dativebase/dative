define ['./../utils/utils'], (utils) ->

  # Paginator
  # ---------
  #
  # Holds attributes and logic for manipulating pagination.

  class Paginator

    constructor: (
      @page = 1
      @items = 0
      @itemsPerPage = 10
      @possibleItemsPerPage = @_defaultPossibleItemsPerPage) ->

      # computed attributes
      @itemsDisplayed = 0
      @pages = 1
      @start = 0
      @end = 1

      @setItemsCalled = false

    # Public methods

    setItems: (newItems) ->
      @items = newItems
      @setItemsCalled = true
      @_refresh()

    # Set `itemsPerPage` manually.
    # If you manually change the items per page, things become a bit complicated.
    # You want your page to start to be near its current value, but you also
    # need it to be a multiple of `itemsPerPage`. This method handles these details
    # of readjusting the paginator given a new items per page.
    setItemsPerPage: (newItemsPerPage) ->
      [@start, @page] = @_getClosestStartValueGivenNewItemsPerPage(
        newItemsPerPage)
      @itemsPerPage = newItemsPerPage
      @_setEnd()
      @_setPages()
      @_setItemsDisplayed()

    setPage: (newPage) ->
      @page = newPage
      @_refresh()

    setPageToFirst: ->
      @page = 1
      @_refresh()

    setPageToPrevious: ->
      if (@page - 1) > 0
        @page = @page - 1
      @_refresh()

    setPageToNext: ->
      if (@page + 1) <= @pages
        @page = @page + 1
      @_refresh()

    setPageToLast: ->
      @page = @pages
      @_refresh()

    incrementPage: (n) ->
      @page = @page + n
      if @page > @pages then @page = @pages
      @_refresh()

    decrementPage: (n) ->
      @page = @page - n
      if @page < 1 then @page = 1
      @_refresh()

    setPossibleItemsPerPage: (newPossibleItemsPerPage) ->
      if utils.type newPossibleItemsPerPage is 'array'
        @possibleItemsPerPage = newPossibleItemsPerPage
      else
        @possibleItemsPerPage = @_defaultPossibleItemsPerPage

    # Private methods

    _refresh: ->
      @_setPages()
      @_setPage()
      @_setStart()
      @_setEnd()
      @_setItemsDisplayed()

    _setStart: ->
      @start = (@page - 1) * @itemsPerPage

    _setEnd: ->
      end = @start + @itemsPerPage - 1
      if end >= @items
        @end = @items - 1
      else
        @end = end

    _setPages: ->
      @pages = Math.ceil(@items / @itemsPerPage)

    _setPage: ->
      if @page > @pages then @page = @pages
      if @page is 0 then @page = 1

    _setItemsDisplayed: ->
      if @itemsPerPage > @items
        @itemsDisplayed = @items
      else
        @itemsDisplayed = @itemsPerPage

    _defaultPossibleItemsPerPage: [1, 2, 3, 5, 10, 25, 50, 100]

    # Return the highest multiple of `newItemsPerPage` such that it is less than
    # or equal to the current `start` value. Also return the `page` value that
    # corresponds to that `start` value. Returns an array of two integers.
    _getClosestStartValueGivenNewItemsPerPage: (newItemsPerPage) ->
      possibleStartValues = @_getPossibleStartValuesGivenNewItemsPerPage(newItemsPerPage)
      currentStartValue = @start
      tmp = (v for v in possibleStartValues when v <= currentStartValue)
      if tmp.length
        [tmp[tmp.length - 1], tmp.length]
      else
        [0, 1]

    # Return the multiples of newItemsPerPage that are less than the number of
    # items in the paginator.
    _getPossibleStartValuesGivenNewItemsPerPage: (newItemsPerPage) ->
      possibleStartValues = []
      possibleStartValue = 0
      while possibleStartValue < @items
        possibleStartValues.push possibleStartValue
        possibleStartValue = possibleStartValue + newItemsPerPage
      possibleStartValues

