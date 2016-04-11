define [
  './field'
  './keyboard-input'
], (FieldView, KeyboardInputView) ->

  # Keyboard Field View
  # -------------------
  #
  # A view for inputing keyboards.

  class KeyboardFieldView extends FieldView

    getFieldLabelContainerClass: ->
      "#{super} top"

    getFieldInputContainerClass: ->
      "#{super} full-width"

    getInputView: ->
      new KeyboardInputView @context

    # We only need inputs on .key-mapping-value textareas to result in a
    # setToModel
    events:
      'input textarea.key-mapping-value': 'setToModel'
      'keydown textarea':                 'controlEnterSubmit'

