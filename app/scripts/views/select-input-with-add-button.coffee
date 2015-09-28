define [
  './select-input'
  './../templates/select-input-with-button'
], (SelectInputView, selectWithButtonTemplate) ->

  # Select Input, with Add Button, View
  # -----------------------------------
  #
  # A view for a data input field that is a <select> and which has a <button>
  # to its right.

  class SelectInputWithAddButtonView extends SelectInputView

    template: selectWithButtonTemplate

    render: ->
      super
      @buttonify()
      @$('button.dative-tooltip').tooltip @tooltipPositionLeft()
      @

    disable: ->
      @disableSelectmenus()
      @disableButtons()

    enable: ->
      @enableSelectmenus()
      @enableButtons()

