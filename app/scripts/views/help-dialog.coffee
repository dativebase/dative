define [
  'backbone'
  './base'
  './../templates/help-dialog'
  'perfectscrollbar'
], (Backbone, BaseView, helpDialogTemplate) ->

  # Help Dialog View
  # ----------------
  #
  # This is a jQueryUI dialog that contains the help document for Dative.
  # That help document is the Markdown file /app/help/src/help.md.
  #
  # This view includes a search interface to that help file.

  class HelpDialogView extends BaseView

    template: helpDialogTemplate

    initialize: ->
      @rendered = false
      @HELP_HTML = ''
      @searchPattern = ''
      @EXPANDED_WIDTH = 500
      @COLLAPSED_WIDTH = 230
      @scrolledToMatchedElementIndex = 0
      @listenTo Backbone, 'helpDialog:toggle', @toggle

    collapsedHeight: ->
      @expandedHeight()

    expandedHeight: ->
      $(window).height() - 50

    events:
      'dialogdragstart': 'closeAllTooltips'
      'dialogresize': 'resizeSearchInput'
      'keyup input[name=help-search]': 'searchHelpText'
      'click a[href]': 'scrollToInternalLink'

    # We have to handle hash-based internal links manually because of
    # scrolling quirks.
    scrollToInternalLink: (event) ->
      href = "#{$(event.target).attr('href')}"
      if href[0] is '#'
        @stopEvent event
        # This is the id value that Markdown generates for headers with named anchors
        headerIdSelector = "##{href[1..]}-a-data-name-#{href[1..]}-a-"
        @scrollToMatch @$(headerIdSelector)

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

    # Search the help document.
    # When a user types a pattern into the help search input, the widget highlights
    # any substrings that match the search pattern and scrolls to the first match.
    # This is regular expression search.
    # Subsequent <Enter> presses focus and scroll to subsequent matches.
    # TODO: <Tab> and <Shift+Tab> should advance and reverse, respectively, the
    # focused element and the scroll position.
    searchHelpText: (event) ->

      if event.which in [13, 40] # <Enter> and <down arrow> mean "scroll to next match"
        console.log 'here'
        @highlightAndScrollToNextMatch()
        return
      else if event.which is 38 # <up arrow> means "scroll to previous match"
        @highlightAndScrollToPreviousMatch()
        return

      searchPattern = $('input[name=help-search]').val()
      if searchPattern is @searchPattern
        return # Do nothing when there's no pattern.

      @searchPattern = searchPattern
      if @searchPattern
        try
          searchRegex = @getSearchRegex()
          @highlightText searchRegex
          $matchedElements = @$('.help-content span.help-match')
          $firstMatchedElement = $matchedElements.first()
          if $firstMatchedElement
            @highlight $firstMatchedElement, $matchedElements
            @scrolledToMatchedElementIndex = 0
            @scrollToMatch $firstMatchedElement
        catch SyntaxError # A bad regex
          console.log 'bad regex syntax error fuck'
          console.log SyntaxError
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
      @rendered = true
      @$el.append @template()
      @$target = @$ '.dative-help-dialog-target'
      @dialogify()
      @guify()
      @perfectScrollbar()
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

    spinnerOptions: ->
      _.extend BaseView::spinnerOptions(), {top: '5%', left: '5%'}

    spin: -> @$('.help-content').spin @spinnerOptions()

    stopSpin: -> @$('.help-content').spin false

    perfectScrollbar: ->
      @$('div.help-content-container').first()
        .perfectScrollbar()
        .scroll => @closeAllTooltips()

    # Transform the help dialog HTML to a jQueryUI dialog box.
    dialogify: ->
      @$('.dative-help-dialog').dialog
        position: @defaultPosition()
        hide: {effect: 'fade'}
        show: {effect: 'fade'}
        autoOpen: false
        appendTo: @$('.dative-help-dialog-target')
        buttons: [
            text: ''
            class: 'help-expand help-button dative-tooltip'
            title: 'Expand and center this help widget'
            click: => @expand()
          ,
            text: ''
            class: 'help-collapse help-button dative-tooltip'
            title: 'Collapse this help widget and move it off to the side'
            click: => @collapse()
        ]
        dialogClass: 'dative-help-dialog-widget'
        title: 'Help'
        width: @COLLAPSED_WIDTH
        minWidth: @COLLAPSED_WIDTH
        maxWidth: 700
        height: $(window).height() - 50
        maxHeight: $(window).height() - 50
        create: =>
          @fontAwesomateCloseIcon()
          @expandCollapseButtons()
        close: =>
          @closeAllTooltips()

    defaultPosition: ->
      my: "right top"
      at: "right-20px top+35px"
      of: @$target.first().parent().parent()

    centerPosition: ->
      my: "center"
      at: "center"
      of: @$target.first().parent().parent()

    expand: ->
      @$('.dative-help-dialog').dialog 'option',
        width: @EXPANDED_WIDTH
        height: @expandedHeight()
        position: @centerPosition()
      @closeAllTooltips()

    collapse: ->
      @$('.dative-help-dialog').dialog 'option',
        width: @COLLAPSED_WIDTH
        height: @collapsedHeight()
        position: @defaultPosition()
      @closeAllTooltips()

    expandCollapseButtons: ->
      @$('.help-expand')
        .html '<i class="fa fa-fw fa-expand"></i>'
        .tooltip()
      @$('.help-collapse')
        .html '<i class="fa fa-fw fa-compress"></i>'
        .tooltip()

    guify: ->
      $searchInput = @$('input[name=help-search]')
      $searchInput
        .width '90%'
        .css('border-color', @constructor.jQueryUIColors().defBo)
      @watermark $searchInput, 'Search help'

    dialogOpen: ->
      Backbone.trigger 'help-dialog:open'
      @$('.dative-help-dialog').dialog 'open'

    dialogClose: -> @$('.dative-help-dialog').dialog 'close'

    isOpen: -> @$('.dative-help-dialog').dialog 'isOpen'

    toggle: ->
      if @isOpen()
        @dialogClose()
      else
        @dialogOpen()

    # Give the input element `$element` a watermark containing `text`.
    watermark: ($element, text) ->
      $element
        .blur ->
          if $(@).val().length is 0 then $(@).val(text).addClass 'watermark'
        .focus ->
          if $(@).val() is text then $(@).val('').removeClass 'watermark'
        .val(text).addClass 'watermark'

