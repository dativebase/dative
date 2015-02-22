define [
  './input'
  './../templates/date-input'
], (InputView, dateTemplate) ->

  # Date Input View
  # ---------------
  #
  # A view for a data input field that is an input[type=text] that is
  # jQueryUI-datepicker-ified.

  class DateInputView extends InputView

    template: dateTemplate

    render: ->
      super
      @tooltipify()
      @datepickerify()
      @

    # Make the date elicited input into a nice jQuery datepickter.
    datepickerify: ->
      @$('input').datepicker
        appendText: "<span style='margin: 0 10px;'>mm/dd/yyyy</span>"
        autoSize: false

    # Make title attrs into jQueryUI tooltips.
    tooltipify: ->
      @$('input.dative-tooltip')
        .tooltip
          position: @tooltipPositionLeft '-200'

