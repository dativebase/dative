define [
  'backbone'
  'jquery'
  './../utils/utils'
  'jqueryuicolors'
], (Backbone, $, utils) ->

  # Base View
  # --------------
  #
  # This is the view that all Dative views should inherit from.
  #
  # The class attribute jQueryUIColors contains all of the color information to
  # match the jQueryUI theme currently in use.
  #
  # The other functionality is from
  # http://blog.shinetech.com/2012/10/10/efficient-stateful-views-with-backbone-js-part-1/ and
  # http://lostechies.com/derickbailey/2011/09/15/zombies-run-managing-page-transitions-in-backbone-apps/
  # It helps in the creation of Backbone views that can keep track of the
  # subviews that they have rendered and can close them appropriately to
  # avoid zombies and memory leaks.

  class BaseView extends Backbone.View

    @debugMode: false

    tooltipsDisabled: true

    # Class attribute that holds the jQueryUI colors of the jQueryUI theme
    # currently in use.
    @jQueryUIColors: ->
      if not @constructor._jQueryUIColors
        @constructor._jQueryUIColors = $.getJQueryUIColors()
      @constructor._jQueryUIColors

    @refreshJQueryUIColors: (callback) ->
      @constructor._jQueryUIColors = $.getJQueryUIColors()
      if callback then callback()

    # TODO: figure out where/how to store/persist user settings
    @userSettings:
      formItemsPerPage: 10

    trim: (string) ->
      string.replace /^\s+|\s+$/g, ''

    snake2camel: (string) ->
      string.replace(/(_[a-z])/g, ($1) ->
        $1.toUpperCase().replace('_',''))

    camel2snake: (string) ->
      string.replace(/([A-Z])/g, ($1) ->
        "_#{$1.toLowerCase()}")

    # Cleanly closes this view and all of it's rendered subviews
    close: ->
      @$el.empty()
      @undelegateEvents()
      @stopListening()
      if @_renderedSubViews?
        for renderedSubView in @_renderedSubViews
          renderedSubView.close()
      @onClose?()

    # Registers a subview as having been rendered by this view
    rendered: (subView) ->
      if not @_renderedSubViews?
        @_renderedSubViews = []
      if subView not in @_renderedSubViews
        @_renderedSubViews.push subView
      return subView

    # Deregisters a subview that has been manually closed by this view
    closed: (subView) ->
      @_renderedSubViews = _.without @_renderedSubViews, subView

    stopEvent: (event) ->
      event.preventDefault()
      event.stopPropagation()

    guid: utils.guid

    utils: utils

    # Cause #dative-page-header to maintain a constant height relative to the
    # window height.
    matchHeights: ->
      pageBody = @$ '#dative-page-body'
      parent = @$(pageBody).parent()
      pageHeader = @$ '#dative-page-header'
      marginTop = parseInt pageBody.css('margin-top')
      marginBottom = parseInt pageBody.css('margin-bottom')
      @_matchHeights pageBody, parent, pageHeader, marginTop, marginBottom
      $(window).resize =>
        @_matchHeights pageBody, parent, pageHeader, marginTop, marginBottom

    _matchHeights: (pageBody, parent, pageHeader, marginTop, marginBottom) ->
      newHeight = parent.innerHeight() - pageHeader.outerHeight() - marginTop -
        marginBottom
      pageBody.css 'height', newHeight
      if @_hasVerticalScrollBar pageBody then pageBody.css 'padding-right', 10

    # Return true if element has a vertical scrollbar
    _hasVerticalScrollBar: (el) ->
      if el.clientHeight < el.scrollHeight then true else false

    closeAllTooltips: ->
      @$('.dative-tooltip').each (index, element) ->
        if $(element).tooltip 'instance'
          $(element).tooltip 'close'

    # Options for spin.js, cf. http://fgnass.github.io/spin.js/
    spinnerOptions: ->
      lines: 13 # The number of lines to draw
      length: 5 # The length of each line
      width: 2 # The line thickness
      radius: 3 # The radius of the inner circle
      corners: 1 # Corner roundness (0..1)
      rotate: 0 # The rotation offset
      direction: 1 # 1: clockwise -1: counterclockwise
      color: @constructor.jQueryUIColors().defCo
      speed: 2.2 # Rounds per second
      trail: 60 # Afterglow percentage
      shadow: false # Whether to render a shadow
      hwaccel: false # Whether to use hardware acceleration
      className: 'spinner' # The CSS class to assign to the spinner
      zIndex: 2e9 # The z-index (defaults to 2000000000)
      top: '0%' # Top position relative to parent
      left: '0%' # Left position relative to parent

    # Logic for remembering and re-focusing the last focused element.

    focusedElementIndex: 0

    rememberFocusedElement: (event) ->
      try
        @$(@focusableSelector).each (index, el) =>
          if el is event.target
            @focusedElementIndex = index

    focusLastFocusedElement: ->
      @$(@focusableSelector).eq(@focusedElementIndex).focus()

    focusFirstElement: ->
      @$(@focusableSelector).eq(0).focus()

    focusableSelector: 'button, input, .ui-selectmenu-button'

    # Alter the scroll position so that the focused UI element is centered.
    scrollToFocusedInput: (event) ->
      # Small bug: if you tab really fast through the inputs, the scroll
      # animations will be queued and all jumpy. Calling `.stop` as below
      # does nof fix the issue.
      # @$('input, button, .ui-selectmenu-button').stop('fx', true, false)

      pageBodySelector = @pageBodySelector or '#dative-page-body'
      $pageBody = @$ pageBodySelector

      $element = $ event.currentTarget

      # Get the true offset of the element
      initialScrollTop = $pageBody.scrollTop()
      $pageBody.scrollTop 0
      trueOffset = $element.offset().top
      $pageBody.scrollTop initialScrollTop

      windowHeight = $(window).height()
      desiredOffset = windowHeight / 2
      scrollTop = trueOffset - desiredOffset
      $pageBody.animate
        scrollTop: scrollTop
        250
        'swing'
        =>
          # Since Dative tooltips close upon scroll events, we have to re-open
          # the tooltip of the focused element after we programmatically scroll
          # here. BUG @jrwdunham: this doesn't work as consistently as I'd like
          # it to. I don't know why yet...
          if $element.hasClass('dative-tooltip') and $element.tooltip('instance')
            $element.tooltip 'open'

    # Fix rounded borders so that adjacently nested rounded borders <divs> don't
    # have a gap between them. This must be done in the JS and not the CSS
    # because Dative can dynamically change the CSS to different jQueryUI
    # themese, which would mess up a static CSS file. (HACK WARN.)
    fixRoundedBorders: ->
      @$('#dative-page-header, .ui-widget > .ui-widget-header').each (index, element) =>
        $el = $ element
        cssProperties = [
          'border-top-left-radius'
          'border-top-right-radius'
          'border-bottom-right-radius'
          'border-bottom-left-radius'
        ]
        $el.css(
          'border-radius',
          _.map(
            _.values($el.css(cssProperties)),
            @decrementPxVal,
            @
          ).join(' ')
        )

    # '6px' becomes '5px', '0px' doesn't change, '1.2em' shouldn't change, etc.
    decrementPxVal: (pxVal) ->
      try
        if @utils.endsWith pxVal, 'px'
          pxInt = Number(pxVal.replace 'px', '')
          if pxInt > 0 then "#{pxInt - 1}px" else pxVal
        else
          pxVal
      catch e
        console.log "exception with #{pxVal}"
        console.log e
        pxVal
