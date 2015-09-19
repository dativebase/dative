define [
  'backbone'
  './input'
  './../templates/password-input'
], (Backbone, InputView, passwordTemplate) ->

  # Password Input View
  # -------------------
  #
  # A view for a data input field that is a password text input.

  class PasswordInputView extends InputView

    template: passwordTemplate

    render: ->
      @$el.html @template(@context)
      @tooltipify()
      @bordercolorify()
      @

    # Make title attrs into jQueryUI tooltips.
    tooltipify: ->
      @$('input.dative-tooltip')
        .tooltip
          position: @tooltipPositionLeft '-200'

    disable: ->
      @disableInputs()

    enable: ->
      @enableInputs()


