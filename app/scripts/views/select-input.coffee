define [
  './input'
  './../templates/select-input'
], (InputView, selectTemplate) ->

  # Select Input View
  # -----------------
  #
  # A view for a data input field that is a <select>.

  class SelectInputView extends InputView

    template: selectTemplate

    render: ->
      super
      @selectmenuify @context.width
      @tooltipify()
      @

    # Make title attrs into jQueryUI tooltips.
    tooltipify: ->
      @$('.ui-selectmenu-button.dative-tooltip')
        .tooltip
          position: @tooltipPositionLeft '-200'

