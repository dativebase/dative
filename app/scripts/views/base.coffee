define [
  'backbone'
  './../utils/utils'
  './../utils/globals'
  './../utils/tooltips'
  'jqueryuicolors'
], (Backbone, utils, globals, tooltips) ->

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

    # Cleanly closes this view and all of it's rendered subviews
    close: ->
      @$el.empty()
      @undelegateEvents()
      @stopListening()
      if @_renderedSubViews?
        for renderedSubView in @_renderedSubViews
          renderedSubView.close()
      @onClose?()

    # Sub-views will call this and/or supplement it, e.g.,
    #   listenToEvents: ->
    #     super
    #     @listenTo someView, 'someEvent', @someMethod
    listenToEvents: ->
      @stopListening()
      @undelegateEvents()
      @delegateEvents()

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
      try
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
      # top: '0%' # Top position relative to parent
      # left: '0%' # Left position relative to parent
      top: '50%'
      left: '98%'

    spin: -> @$('#dative-page-header').spin @spinnerOptions()

    stopSpin: -> @$('#dative-page-header').spin false


    # Logic for remembering and re-focusing the last focused element.

    focusedElementIndex: 0

    rememberFocusedElement: (event) ->
      try
        @$(@focusableSelector).each (index, el) =>
          if el is event.target
            @focusedElementIndex = index

    focusLastFocusedElement: ->
      @focusElement @focusedElementIndex

    focusElement: (index) ->
      $focusables = @$ @focusableSelector
      $elementToSelect = $focusables.eq index
      if $elementToSelect.hasClass 'ui-state-disabled'
        @focusFirstElement()
      else
        $elementToSelect.focus()

    # This is the default selector for the things that Dative considers to be
    # "focusable". Views may override this to achieve certain behaviour.
    focusableSelector: 'button, input, .ui-selectmenu-button'

    # Focus the first focusable element in the view.
    focusFirstElement: ->
      @$(@focusableSelector)
        .filter(':visible')
        .not('.ui-state-disabled')
        .eq(0)
          .focus()

    # Focus the last focusable element in the view.
    focusLastElement: ->
      @$(@focusableSelector)
        .filter(':visible')
        .not('.ui-state-disabled')
        .eq(-1)
          .focus()

    # Alter the scroll position so that the focused UI element is centered.
    scrollToFocusedInput: (event) ->
      try
        @_scrollToFocusedInput event

    # Alter the scroll position so that the focused UI element is centered.
    _scrollToFocusedInput: (event) ->
      # Small bug: if you tab really fast through the inputs, the scroll
      # animations will be queued and all jumpy. Calling `.stop` as below
      # does nof fix the issue.
      # @$('input, button, .ui-selectmenu-button').stop('fx', true, false)

      pageBodySelector = @pageBodySelector or '#dative-page-body'
      $pageBody = @$ pageBodySelector

      try
        $element = $ event.currentTarget
      catch
        $element = @$ ':focus'

      # Find the desired `scrollTop`, i.e., the pixel value we should pass to
      # `$.scrollTop` in order get our focused element where we want it.

      # `scrollTop = true-offset - (window-height / 2)
      # Initial scroll-top: (hidden) vertical space above the focused element.
      # `.scrollTop`: "the current vertical position of the scroll bar for the
      # first element in the set of matched elements. The number of pixels that
      # are hidden from view above the scrollable area."

      # Calling `scrollTop()` moves us to the top and returns our
      # `.offset().top` value *prior* to scrolling.
      initialScrollTop = $pageBody.scrollTop() # where we started from

      # Get the true offset of the element.
      # That is, find out how far from the top the element is when we are
      # scrolled to the very top.
      $pageBody.scrollTop 0 # scroll to the top
      elementOffset = $element.offset().top

      # Get the window height.
      $pageBody.scrollTop initialScrollTop # scroll back to where we started from
      windowHeight = $(window).height()

      #desiredOffset = windowHeight / 2
      desiredOffset = windowHeight * (1 / 4)

      scrollTop = elementOffset - desiredOffset

      if scrollTop isnt initialScrollTop
        $pageBody.stop().animate
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

    scrollToTop: ->
      @$('#dative-page-body').animate
        scrollTop: 0
        250
        'swing'

    scrollToBottom: ->
      $pageBody = @$ '#dative-page-body'
      pageBodyHeight = $pageBody.height()
      @$('#dative-page-body').animate
        scrollTop: pageBodyHeight
        250
        'swing'

    # Fix rounded borders so that adjacently nested rounded borders <divs> don't
    # have a gap between them. This must be done in the JS and not the CSS
    # because Dative can dynamically change the CSS to different jQueryUI
    # themese, which would mess up a static CSS file. (HACK WARN.)
    fixRoundedBorders: ->
      selector = '#dative-page-header, .ui-widget > .ui-widget-header'
      @$(selector).each (index, element) =>
        @fixRoundedBorder element

    fixRoundedBorder: (element) ->
        if element instanceof $
          $el = element
        else
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
        pxVal

    # When a widget's body is CLOSED, its header SHOULD have rounded bottom
    # corners.
    setHeaderStateClosed: ->
      $header = @$('.dative-widget-header').first()
      $header.addClass 'header-no-body ui-corner-bottom'
      $header.css
        'border-bottom-left-radius': $header.css('border-top-left-radius')
        'border-bottom-right-radius': $header.css('border-top-right-radius')

    # When a widget's body is OPEN, its header should NOT have rounded bottom
    # corners.
    setHeaderStateOpen: ->
      $header = @$('.dative-widget-header').first()
      $header.removeClass 'header-no-body ui-corner-bottom'
      $header.css
        'border-bottom-left-radius': 0
        'border-bottom-right-radius': 0

    # Hack for changing the close "X" of a jQueryUI dialog to a font-awesome
    # fa-close "X".
    fontAwesomateCloseIcon: ->
      newIconHTML = [
        '<span class="ui-button-text">',
        '<i class="fa fa-fw fa-close" ',
        'style="position: relative; right: 0.48em; bottom: 0.45em;"></i></span>'
      ].join ''
      @$target.find('button.ui-dialog-titlebar-close')
        .find('span.ui-button-icon-primary').remove().end()
        .removeClass 'ui-button-icon-only'
        .addClass 'ui-button-text-only'
        .html newIconHTML

    getActiveServerType: ->
      try
        globals.applicationSettings.get('activeServer').get 'type'
      catch
        null

    getLoggedInUsername: ->
      try
        globals.applicationSettings.get 'username'
      catch
        null

    # Tooltip position: top-aligned and to the left.
    # Return a default tooltip position where the tops are aligned and the right
    # side of the tooltip is `rightOffset` away from the left side of the target.
    tooltipPositionLeft: (rightOffset='-120') ->
      my: "right#{rightOffset} top"
      at: 'left top'
      collision: 'flipfit'

    # Tooltip position: top-aligned and to the left.
    # Return a default tooltip position where the tops are aligned and the right
    # side of the tooltip is `rightOffset` away from the left side of the target.
    tooltipPositionRight: (leftOffset='+20') ->
      my: "left#{leftOffset} top"
      at: 'right top'
      collision: 'flipfit'

    # Copy the class and title attributes from a <select> to its corresponding
    # selectmenu button. This permits later "tooltipification".
    transferClassAndTitle: ($element, selector='.ui-selectmenu-button') ->
      class_ = $element.attr 'class'
      title = $element.attr 'title'
      $element
        .next selector
          .addClass "#{class_} dative-tooltip"
          .attr 'title', title

    grammaticalitySelectmenuWidth: '8%'

    # Take what jQuery's `serializeArray` gives you and return an object.
    serializeObject: (arrayOfObjects) ->
      result = {}
      for object in arrayOfObjects
        result[object.name] = object.value
      result

    # Merge an array of objects: _.extend on an array of objects.
    arrayOfObjectsToObject: (arrayOfObjects) ->
      result = {}
      for object in arrayOfObjects
        _.extend result, object
      result

