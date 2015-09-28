define [
  'backbone'
  './dialog-base'
  './../templates/help-dialog'
], (Backbone, DialogBaseView, helpDialogTemplate) ->

  # Help Dialog View
  # ----------------
  #
  # This is a jQueryUI dialog that contains the help document for Dative.
  # That help document is the Markdown file /app/help/src/help.md.
  #
  # This view includes a search interface to that help file.

  class HelpDialogView extends DialogBaseView

    template: helpDialogTemplate

    # This is the class selector of the <div> in the template that becomes
    # dialogified.
    getDialogClassSelector: -> '.dative-help-dialog'

    # This is a class name that should be passed in as the value of the
    # `.dialog` method's `dialogClass` param. It will be a class name in the
    # .ui-dialog.ui-widget <div> that holds everything.
    getDialogWidgetClass: -> 'dative-help-dialog-widget'

    initialize: ->
      @hasBeenRendered = false
      @HELP_HTML = ''
      @searchPattern = ''
      @EXPANDED_WIDTH = 500
      @setDimensions()
      @lastPosition = null
      @scrolledToMatchedElementIndex = 0
      @postHTMLRetrievedAction = null # may be specified as a method to call once the Help HTML has been retrieved.
      @listenTo Backbone, 'helpDialog:toggle', @toggle
      @listenTo Backbone, 'helpDialog:openTo', @openTo

    collapsedHeight: ->
      @expandedHeight()

    expandedHeight: ->
      $(window).height() - 50

    minimizedPosition: -> @defaultPosition()

    getMinimizedWidth: (windowWidth) -> 230
    getMinWidth: (windowWidth) -> 230
    getWidth: (windowWidth) -> 230
    getMaxWidth: (windowWidth) -> 700

    getHeight: (windowHeight) -> windowHeight - 50
    getMaxHeight: (windowHeight) -> @getHeight windowHeight

    events:
      'click .minimize': 'minimize'
      'click .maximize': 'maximize'
      'keyup input[name=help-search]': 'keyupEventInHelpSearchInput'
      'click a[href]': 'scrollToInternalLink'

    # We have to handle hash-based internal links manually because of
    # scrolling quirks.
    scrollToInternalLink: (event) ->
      href = "#{$(event.target).attr('href')}"
      if href[0] is '#'
        @stopEvent event
        # This is the id value that Markdown generates for headers with named anchors
        headerIdSelector = "##{href[1..]}-a-data-name-#{href[1..]}-a-"
        @scrollToElementById headerIdSelector

    scrollToElementById: (idSelector) ->
      @scrollToMatch @$(idSelector)

    # Highlight a specific match.
    highlight: ($matchedElement, $matchedElements) ->
      $matchedElements.removeClass 'focused-help-match'
      $matchedElement.addClass 'focused-help-match'

    # Highlight the next match in the queue, and scroll to it.
    highlightAndScrollToNextMatch: ->
      oldScrolledToMatchedElementIndex = @scrolledToMatchedElementIndex
      $matchedElements = @getMatchedElements()
      $nextMatchedElement = @getNextMatchedElement $matchedElements
      if $nextMatchedElement
        @highlightAndScrollToElement $nextMatchedElement, $matchedElements
      else
        @scrolledToMatchedElementIndex = oldScrolledToMatchedElementIndex

    # Highlight the previous match in the queue, and scroll to it.
    highlightAndScrollToPreviousMatch: ->
      oldScrolledToMatchedElementIndex = @scrolledToMatchedElementIndex
      $matchedElements = @getMatchedElements()
      $previousMatchedElement = @getPreviousMatchedElement $matchedElements
      if $previousMatchedElement
        @highlightAndScrollToElement $previousMatchedElement, $matchedElements
      else
        @scrolledToMatchedElementIndex = oldScrolledToMatchedElementIndex

    getMatchedElements: -> @$ '.help-content span.help-match'

    # Get the next search match.
    getNextMatchedElement: ($matchedElements) ->
      @scrolledToMatchedElementIndex += 1
      if @scrolledToMatchedElementIndex >= $matchedElements.length
        @scrolledToMatchedElementIndex = 0
        $nextMatchedElement = $matchedElements.eq @scrolledToMatchedElementIndex
      else
        $nextMatchedElement = $matchedElements.eq @scrolledToMatchedElementIndex

    # Get the previous search match.
    getPreviousMatchedElement: ($matchedElements) ->
      @scrolledToMatchedElementIndex -= 1
      if @scrolledToMatchedElementIndex < 0
        @scrolledToMatchedElementIndex = $matchedElements.length - 1
        $previousMatchedElement = $matchedElements.eq @scrolledToMatchedElementIndex
      else
        $previousMatchedElement = $matchedElements.eq @scrolledToMatchedElementIndex

    # Highlight an element and scroll to it.
    highlightAndScrollToElement: ($element, $elements) ->
      @highlight $element, $elements
      @scrollToMatch $element

    # Highlight the help document, essentially by rewriting it with a
    # version where all matches are wrapped in special <span>s.
    highlightText: (searchRegex) ->
      newHelpContent = @HELP_HTML.replace(searchRegex, @highlightSearchMatch)
      @$('.help-content').html newHelpContent

    # Highlight a search match, i.e., wrap it in classed <span> tags.
    highlightSearchMatch: (match) ->
      if match[0] is '<'
        match
      else
        "<span class='ui-state-highlight help-match' tabindex='0'>#{match}</span>"

    ############################################################################
    # Search code.
    ############################################################################

    # Return a regex corresponding to the user-entered regex, but which filters
    # out HTML tags (i.e., doesn't search in them).
    getSearchRegex: ->
      ///
        <[^<>]+>             # match an HTML tag: will be replaced by itself
        | #{@searchPattern}  # match the search pattern
      ///gi

    # Handle keyup events in the text input for searching the help document.
    # When a user types a pattern into the help search input, the widget highlights
    # any substrings that match the search pattern and scrolls to the first match.
    # Subsequent <Enter> or <down-arrow> presses focus and scroll to subsequent
    # matches while <up-arrow> presses focus and scroll to previous matches.
    # TODO: <Tab> and <Shift+Tab> should advance and reverse, respectively, the
    # focused element and the scroll position.
    keyupEventInHelpSearchInput: (event) ->
      if event.which in [13, 40] # <Enter> and <down arrow> mean "scroll to next match"
        @highlightAndScrollToNextMatch()
        return
      else if event.which is 38 # <up arrow> means "scroll to previous match"
        @highlightAndScrollToPreviousMatch()
        return

      searchPattern = @$('input[name=help-search]').val()
      if searchPattern is @searchPattern
        return # Do nothing when there's no new pattern.

      @searchHelpText searchPattern

    # Search the help document.
    # This is regular expression search.
    searchHelpText: (searchPattern, scrollToIndex=0) ->
      @searchPattern = searchPattern
      if @searchPattern
        try
          searchRegex = @getSearchRegex()
          @highlightText searchRegex
          $matchedElements = @$('.help-content span.help-match')
          $scrollTo = $matchedElements.eq scrollToIndex
          if scrollToIndex > 0 and not $scrollTo
            scrollToIndex = 0
            $scrollTo = $matchedElements.first()
          if $scrollTo
            @highlight $scrollTo, $matchedElements
            @scrolledToMatchedElementIndex = scrollToIndex
            @scrollToMatch $scrollTo
        catch SyntaxError # A bad regex
          return
      else
        @$('.help-content').html @HELP_HTML
        @scrollToTop()

    # Scroll to the top of the help dialog.
    scrollToTop: ->
      @$('.help-content-container').animate
        scrollTop: 0
        250
        'swing'

    # Alter the scroll position so that the first match is visible.
    scrollToMatch: ($matchedElement) ->
      if $matchedElement.length is 0 then return

      $pageBody = @$ '.help-content-container'

      # Get the true offset of the element
      initialScrollTop = $pageBody.scrollTop()
      $pageBody.scrollTop 0
      trueOffset = $matchedElement.offset().top
      $pageBody.scrollTop initialScrollTop

      pageBodyHeight = $pageBody.height()
      desiredOffset = pageBodyHeight / 2
      scrollTop = trueOffset - desiredOffset

      $pageBody.animate
        scrollTop: scrollTop
        250
        'swing'

    resizeSearchInput: (event, ui) ->
      @$('input[name=help-search]').first().css('width', ui.size.width - 50)

    render: ->
      @hasBeenRendered = true
      @$el.append @template()
      @$target = @$ '.dative-help-dialog-target'
      @dialogify()
      @addHeaderButtons()
      @guify()
      @$('div.help-content-container').first().scroll => @closeAllTooltips()
      @getHelpHTML()
      @

    # This is the HTML (from markdown) in /app/help/html/help.html
    getHelpHTML: ->
      @spin()
      $
        .ajax
          type: "GET"
          url: "/help/html/help.html"
        .done (helpHTML) =>
          @HELP_HTML = helpHTML
          @stopSpin()
          @$('.help-content').html @HELP_HTML
          if @postHTMLRetrievedAction
            @postHTMLRetrievedAction()
            @postHTMLRetrievedAction = null


    spinnerOptions: ->
      _.extend DialogBaseView::spinnerOptions(), {top: '5%', left: '5%'}

    spin: -> @$('.help-content').spin @spinnerOptions()

    stopSpin: -> @$('.help-content').spin false

    # Transform the help dialog HTML to a jQueryUI dialog box.
    dialogify: ->
      @$('.dative-help-dialog').dialog
        position: (=> @defaultPosition())()
        hide: {effect: 'fade'}
        show: {effect: 'fade'}
        autoOpen: false
        appendTo: @$('.dative-help-dialog-target')
        buttons: []
        dialogClass: @getDialogWidgetClass()
        title: 'Help'
        # width: @COLLAPSED_WIDTH
        # maxWidth: 700
        width: @width
        maxWidth: @maxWidth
        minWidth: @minWidth
        # height: $(window).height() - 50
        # maxHeight: $(window).height() - 50
        height: @height
        maxHeight: @maxHeight
        create: =>
          @fontAwesomateCloseIcon()
        close: =>
          @closeAllTooltips()
        resizeStop: (event, ui) => @resizeStop event, ui
        dragStart: => @closeAllTooltips()
        dragStop: (event, ui) => @dragStop event, ui

    defaultPosition: ->
      my: "right top"
      at: "right-20px top+35px"
      of: window

    getMaximizedPosition: ->
      if @lastPosition then @lastPosition else @centerPosition()

    centerPosition: ->
      my: "center"
      at: "center"
      of: window

    guify: ->
      $searchInput = @$('input[name=help-search]')
      $searchInput
        .width '90%'
        .css('border-color', @constructor.jQueryUIColors().defBo)
      @watermark $searchInput, 'Search help'
      @guifyHeaderButtons()

    dialogOpen: ->
      Backbone.trigger 'help-dialog:open'
      @$('.dative-help-dialog').dialog 'open'

    dialogClose: -> @$('.dative-help-dialog').dialog 'close'

    isOpen: -> @$('.dative-help-dialog').dialog 'isOpen'

    toggle: (options) ->
      if not @hasBeenRendered
        # This tells us to call `toggle` again once the help dialog has been
        # rendered (and its HTML have been retrieved from the Dative server).
        @postHTMLRetrievedAction = => @toggle options
        @render()
        return
      if @isOpen()
        @dialogClose()
      else
        @dialogOpen()
        @simulateSearchHelpText options

    openTo: (options) ->
      if not @hasBeenRendered
        # This tells us to call `toggle` again once the help dialog has been
        # rendered (and its HTML have been retrieved from the Dative server).
        @postHTMLRetrievedAction = => @openTo options
        @render()
      else
        if not @isOpen() then @dialogOpen()
        @simulateSearchHelpText options

    # Make it seem as though `options.searchTerm` has been searched in
    # the help text: put the search term in the input, focus the input,
    # highlight the matches, focus the `scrollToIndex`ed match and scroll
    # to it.
    simulateSearchHelpText: (options) ->
      if options?.searchTerm
        @$('input[name=help-search]')
          .focus()
          .val options.searchTerm
        if options.scrollToIndex
          @searchHelpText options.searchTerm, options.scrollToIndex
        else
          @searchHelpText options.searchTerm

    # Give the input element `$element` a watermark containing `text`.
    watermark: ($element, text) ->
      $element
        .blur (e) =>
          $input = @$ e.target
          if $input.val().length is 0
            $input
              .val text
              .addClass 'watermark'
        .focus (e) =>
          $input = @$ e.target
          if $input.val() is text
            $input
              .val ''
              .removeClass 'watermark'
        .val(text).addClass 'watermark'

