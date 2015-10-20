define [
  './textarea-field'
  './../utils/globals'
], (TextareaFieldView, globals) ->

  # Suggestion Receiver Field
  # -------------------------
  #
  # The purpose of this field view is to provide methods to be mixed into other
  # field views that are "suggestion receivers", i.e., which receive suggested
  # values from other fields.

  class SuggestionReceiverFieldView extends TextareaFieldView

    # Extra GUI niceties for our suggestion machinery.
    guifyForSuggestions: ->
      @$('.suggestions')
        .css "border-color", @constructor.jQueryUIColors().defBo
      @$('button.toggle-suggestions')
        .button()
        .tooltip()
        .hide()
      setTimeout (=> @resizeAndPositionSuggestionsDiv()), 10

    hoverStateSuggestionOn: (event) ->
      @$(event.currentTarget).addClass 'ui-state-hover'

    hoverStateSuggestionOff: (event) ->
      @$(event.currentTarget).removeClass 'ui-state-hover'

    # <Ctrl+Enter> should still submit the form, but now <down arrow> should
    # open the suggestions <div>.
    # NOTE: I stopped stopping the event because stopping it means that you can
    # no longer move up and down within the textarea using the arrow keys.
    # However, this doesn't really fix things for the down arrow since in that
    # case the first suggestion becomes highlighted and you don't move to the
    # next line (or end of) the textarea anyways.
    myControlEnterSubmit: (event) ->
      switch event.which
        when 40
          # @stopEvent event
          @openSuggestionsAnimateCheck()
        when 38
          # @stopEvent event
          if @$('.suggestions').length > 0 then @closeSuggestionsAnimate()
      @controlEnterSubmit event

    # We have received a suggestion; respond accordingly. This means:
    # 1. potentially inserting the (primary) suggestion into our <textarea>
    # 2. populating our .suggestions <div> with (a subset of) the suggestions.
    # 3. alerting the user if their current value is not in the suggestions
    #    list.
    suggestionReceived: (suggestion) ->
      $input = @$("textarea[name=#{@attribute}]").first()
      currentValue = $input.val().trim()
      @suggestionUnaltered = suggestion
      @suggestedValues = @getSuggestedValues suggestion
      if (@systemSuggested or (not currentValue)) and
      @suggestedValues.length > 0
        @systemSuggested = true
        $input.val @suggestedValues[0]
        @setToModel()
      @addSuggestionsToSuggestionsDiv()

    turnOffSuggestions: ->
      @closeSuggestionsAnimate()
      @suggestionsVisible = false
      @toggleSuggestionsButtonState()
      @suggestedValues = []

    # Due to combinatoric explosion, we can get too many suggestions, so we
    # display this many at most.
    maxNoSuggestions: 20

    # Populate our .suggestions <div> with our first `@maxNoSuggestions`
    addSuggestionsToSuggestionsDiv: ->
      if @suggestedValues.length > 0
        @alertIncongruity()
        @showSuggestionsButtonCheck()
        @$('.suggestions').first().html @getSuggestedValuesHTML()
        # If nothing is currently focused, we take that to mean that the last
        # thing focused was a .suggestion <div> that we just destroyed; so we
        # focus the first new .suggestion <div>.
        if $(':focus').length is 0
          @$('.suggestions').first().find('.suggestion').first().focus()
      else
        @$('.suggestions').html ''
        @hideSuggestionsButtonCheck()

    # We set the width and position of the .suggestions <div> in accordance
    # with the with and position of the <textarea> that the suggestions are
    # for.
    # TODO: fix minor bug: right now the .suggestions <div> will be incorrectly
    # positioned when first revealed. It quickly fixes itself, but this could
    # be better.
    resizeAndPositionSuggestionsDiv: ->
      $textarea = @$("textarea[name=#{@attribute}]").first()
      $suggestionsDiv = @$('.suggestions').first()
      textareaWidth = $textarea.width()
      if textareaWidth
        newWidth = @getNewWidth textareaWidth
        $suggestionsDiv.css 'width', "#{newWidth}px"
      if $suggestionsDiv.is ':visible'
        $suggestionsDiv.position
          my: 'left top'
          at: 'left bottom-5'
          of: $textarea
          collision: 'none'

    # Get the HTML for displaying our array of selections (truncated, if
    # needed).
    getSuggestedValuesHTML: ->
      result = []
      for suggestion in @suggestedValues[...@maxNoSuggestions]
        result.push "<div class='suggestion' tabindex='0'>#{suggestion}</div>"
      result.join ''

    # Alert the user to the fact that their value does not match any of the
    # values in the received suggestion. We perform this alert by adding an
    # Error class to the small "show suggestions" button, changing the tooltip
    # message, and giving it an "Error" appearance too.
    alertIncongruity: ->
      if @suggestedValues and @suggestedValues.length > 0
        value = @model.get @attribute
        if @userValueInSuggestedValues value
          @$('button.toggle-suggestions').first()
            .removeClass 'ui-state-error'
            .tooltip 'option', 'content', 'show suggested values for this field'
            .tooltip 'option', 'tooltipClass', ''
        else
          @$('button.toggle-suggestions').first()
            .addClass 'ui-state-error'
            .tooltip 'option', 'content', "Warning: the value in this field is
              not among the values suggested by
              #{@suggestionUnaltered.suggester} given the
              #{@utils.snake2regular @suggestionUnaltered.source} value; click
              here to show suggested values for this field"
            .tooltip 'option', 'tooltipClass', 'ui-state-error'

    # Respond to a 'click' event on a <div.selection> element: put its
    # suggestion text in our <textarea>.
    suggestionClicked: (event) ->
      suggestion = @$(event.currentTarget).text()
      $textarea = @$("textarea[name=#{@attribute}]").first()
      $textarea.val suggestion
      @setToModel()
      @suggestionsVisible = false
      @toggleSuggestionsButtonState()
      @$('.suggestions').first().slideUp
        complete: -> $textarea.focus()

    # (Animatedly) toggle the suggestions <div>.
    toggleSuggestions: ->
      $suggestionsDiv = @$('.suggestions').first()
      if $suggestionsDiv.is ':visible'
        @suggestionsVisible = false
        $suggestionsDiv.slideUp()
      else
        @suggestionsVisible = true
        $suggestionsDiv.slideDown
          complete: =>
            @resizeAndPositionSuggestionsDiv()
      @toggleSuggestionsButtonState()

    # Open the suggestions <div> (animatedly) and focus the first suggestion.
    openSuggestionsAnimateCheck: ->
      if @suggestedValues.length > 0
        @suggestionsVisible = true
        $suggestionsDiv = @$('.suggestions').first()
        if not $suggestionsDiv.is ':visible'
          $suggestionsDiv.slideDown
            complete: =>
              @resizeAndPositionSuggestionsDiv()
        $suggestionsDiv.find('.suggestion').first().focus()
      else
        @suggestionsVisible = false
      @toggleSuggestionsButtonState()

    # Close the suggestions <div> (animatedly) and focus our <textarea>.
    closeSuggestionsAnimate: ->
      @suggestionsVisible = false
      @toggleSuggestionsButtonState()
      @$('.suggestions').first().slideUp()
      @$("textarea[name=#{@attribute}]").first().focus()

    # The suggestions <div> has caught a keydown event:
    # - down arrow focuses next suggestion
    # - up arrow focuses previous suggestion (or closes <div> if at top)
    # - <Return> selects focused suggestion (puts it in <textarea>)
    # - <Esc> closes suggestions <div> and focuses textarea
    suggestionsKeyboardControl: (event) ->
      switch event.which
        when 40
          @stopEvent event
          $focused = @$(':focus')
          $next = $focused.next()
          if $next then $next.focus()
        when 38
          @stopEvent event
          $focused = @$(':focus')
          $prev = $focused.prev()
          if $prev.length > 0
            $prev.focus()
          else
            @closeSuggestionsAnimate()
        when 13
          @stopEvent event
          @$(event.currentTarget).click()
        when 27
          @stopEvent event
          @closeSuggestionsAnimate()

    # title='show suggested values for this <%= @label %> field'
    toggleSuggestionsButtonState: ->
      $button = @$ 'button.toggle-suggestions'
      if @suggestionsVisible
        $button.tooltip content: "hide suggested values for this
          #{@context.label} field"
      else
        $button.tooltip content: "show suggested values for this
          #{@context.label} field"

    # Show the "toggle suggestions" button if it's not yet visible.
    showSuggestionsButtonCheck: ->
      $button = @$('button.toggle-suggestions')
      if not $button.is(':visible') then $button.show()

    # Hide the "toggle suggestions" button (if it is visible).
    hideSuggestionsButtonCheck: ->
      $button = @$('button.toggle-suggestions')
      if $button.is(':visible') then $button.hide()

