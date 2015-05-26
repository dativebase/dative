define [
  './field'
  './script-input'
], (FieldView, ScriptInputView) ->

  # Script Field View
  # -------------------
  #
  # A view for inputing scripts, i.e., phonology scripts. 
  # - an auto-expanding textarea
  # - takes up 90%
  # - has a label above, not to the side, so no space is lost

  class ScriptFieldView extends FieldView

    getFieldLabelContainerClass: ->
      "#{super} top"

    getFieldInputContainerClass: ->
      "#{super} full-width"

    getInputView: ->
      new ScriptInputView @context

