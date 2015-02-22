define [
  './field'
  './date-input'
], (FieldView, DateInputView) ->

  # Date Field View
  # ---------------
  #
  # A view for a data input field that is an input[type=text] which is
  # jQueryUI-datepicker-ified.

  class DateFieldView extends FieldView

    getInputView: ->
      new DateInputView @context

