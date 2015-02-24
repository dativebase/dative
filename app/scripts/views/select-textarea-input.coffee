define [
  'backbone'
  './input'
  './../templates/select-textarea-input'
], (Backbone, InputView, selectTextareaTemplate) ->

  # Select Textarea Input View
  # --------------------------
  #
  # A view for a set of input controls consisting of:
  # - a <select> (selectmenu)
  # - a <textarea>

  class SelectTextareaInputView extends InputView

    template: selectTextareaTemplate

    initialize: (@context) ->
      @selectClass = @context.selectClass

    events:
      'selectmenuchange': 'resetTextareaWidth'

    render: ->
      @$el.html @template(@context)
      @selectmenuify()
      @tooltipify()
      @resetTextareaWidth()
      @autosize()
      @bordercolorify()
      @listenToEvents()
      @

    listenToEvents: ->
      super
      @listenTo Backbone, 'addFormWidgetVisible', @resetTextareaWidth

    # Make title attrs into jQueryUI tooltips.
    tooltipify: ->
      @$('textarea.dative-tooltip')
        .tooltip
          position: @tooltipPositionLeft '-250'
      @$(".ui-selectmenu-button.#{@selectClass}.dative-tooltip")
        .tooltip
          position: @tooltipPositionLeft '-200'

    # Alter the <textarea> width so that the <select> and the <button> are all
    # on the same line. This is called in response to a selectmenu change event.
    resetTextareaWidth: ->
      if @$el.is(':visible')
        $textarea = @$('textarea').first()
        selectWidth = @$('.ui-selectmenu-button').first().width()
        buffer = 33
        textareaNewWidth = @$el.width() - selectWidth - buffer
        $textarea.css 'width': textareaNewWidth

