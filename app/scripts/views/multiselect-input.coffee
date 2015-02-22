define [
  './input'
  './../templates/multiselect-input'
  'multiselect'
], (InputView, multiselectTemplate) ->

  # Multiselect Input View
  # ----------------------
  #
  # A view for a data input field that is a <select> that is
  # jQueryUI-multiSelect-ified.

  class MultiselectInputView extends InputView

    template: multiselectTemplate

    render: ->
      super
      @multiselectify()
      @tooltipify()
      @

    # Make the tags <select> into a jQuery multiSelect
    multiselectify: ->
      @$('select')
        .multiSelect()
        .each (index, element) =>
          @transferClassAndTitle @$(element), '.ms-container'

    # Make title attrs into jQueryUI tooltips.
    tooltipify: ->
      @$('div.ms-container.dative-tooltip')
        .tooltip
          position: @tooltipPositionLeft '-200'

