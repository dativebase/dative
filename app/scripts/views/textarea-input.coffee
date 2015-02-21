define [
  'backbone'
  './input'
  './../templates/textarea-input'
], (Backbone, InputView, textareaTemplate) ->

  # Textarea Input View
  # -------------------
  #
  # A view for a data input field that is a textarea.

  class TextareaInputView extends InputView

    template: textareaTemplate

    initialize: (@context) ->

    render: ->
      @$el.html @template(@context)
      @tooltipify()
      @bordercolorify()
      @autosize()
      @

    # Make title attrs into jQueryUI tooltips.
    tooltipify: ->
      @$('textarea.dative-tooltip')
        .tooltip
          position: @tooltipPositionLeft '-200'

