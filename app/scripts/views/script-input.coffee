define [
  './textarea-input'
  './../templates/script-input'
], (TextareaInputView, scriptTemplate) ->

  # Script Input View
  # -----------------
  #
  # A view for a data input field that is a textarea for writing phonology
  # scripts.

  class ScriptInputView extends TextareaInputView

    template: scriptTemplate

    render: ->
      @$el.html @template(@context)
      @tooltipify()
      @bordercolorify()
      @
