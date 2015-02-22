define [
  'backbone'
  './input'
  './../templates/input-textarea-input'
], (Backbone, InputView, inputTextareaTemplate) ->

  # Input Textarea Input View
  # -------------------------
  #
  # A view for a set of input controls consisting of:
  # - an <input>
  # - a <textarea>

  class InputTextareaInputView extends InputView

    template: inputTextareaTemplate

    render: ->
      super
      @tooltipify()
      @

    # Make title attrs into jQueryUI tooltips.
    tooltipify: ->
      @$('textarea.dative-tooltip')
        .tooltip
          position: @tooltipPositionLeft '-250'
      @$('input.dative-tooltip')
        .tooltip
          position: @tooltipPositionLeft '-200'

