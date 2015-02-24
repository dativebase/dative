define [
  'backbone'
  './input'
  './../templates/select-textarea-button-input'
], (Backbone, InputView, selectTextareaButtonTemplate) ->

  # Select Textarea Button Input View
  # ---------------------------------
  #
  # A view for a set of input controls consisting of:
  # - a <select> (selectmenu)
  # - a <textarea>
  # - a <button> for adding a new one of these or for deleting this one.

  class SelectTextareaButtonInputView extends InputView

    className: 'dative-field-subinput-container'

    template: selectTextareaButtonTemplate

    initialize: (@context) ->
      # The element of this view will have a class like "translations-0" where
      # "0" is a unique index in the array of translations.
      @selectClass = @context.selectClass
      @$el.addClass "#{@context.attribute}-#{@context.index}"

    events:
      'selectmenuchange': 'resetTextareaWidth'
      'click button.new': 'newSelectTextareaButtonInputView'
      'click button.remove': 'removeMe'

    # The adding of a new select-textarea-button input view is handled by this
    # view's superview: `TranslationsInputView`.
    newSelectTextareaButtonInputView: -> @trigger 'new'

    # The removing of a new select-textarea-button input view is also handled
    # by this view's superview: `TranslationsInputView`.
    removeMe: ->
      @trigger 'remove', @context.index

    render: ->
      @$el.html @template(@context)
      @selectmenuify()
      @tooltipify()
      @buttonify()
      @resetTextareaWidth()
      @autosize()
      @bordercolorify()
      @listenToEvents()
      @

    listenToEvents: ->
      super
      @listenTo Backbone, 'addFormWidgetVisible', @resetTextareaWidth

    # Alter the <textarea> width so that the <select> and the <button> are all
    # on the same line. This is called in response to a selectmenu change event.
    resetTextareaWidth: ->
      if @$el.is(':visible')
        $textarea = @$('textarea').first()
        selectWidth = @$('.ui-selectmenu-button').first().width()
        buttonWidth = @$('button').first().width()
        buffer = 39
        textareaNewWidth = @$el.width() - selectWidth - buttonWidth - buffer
        $textarea.css 'width': textareaNewWidth

    # Make title attrs into jQueryUI tooltips.
    tooltipify: ->
      @$('textarea.dative-tooltip')
        .tooltip
          position: @tooltipPositionLeft '-250'
      @$(".ui-selectmenu-button.#{@context.selectClass}.dative-tooltip")
        .tooltip
          position: @tooltipPositionLeft '-200'
      @$('button')
        .tooltip
          position: @tooltipPositionRight()

