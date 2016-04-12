define [
  './field-display'
  './keyboard-field'
  './keyboard-input'
], (FieldDisplayView, KeyboardFieldView, KeyboardInputView) ->

  class KeyboardRepresentationView extends KeyboardInputView

    initialize: (@context) ->
      super @context
      @context.editable = false

    events:
      'keydown': 'highlightKeyByKeycode'
      'keydown .keyboard-test-input': 'interceptKey'
      'keyup': 'dehighlightKeyByKeycode'
      'mousedown .keyboard-table-cell': 'highlightFocusedKey'
      'mouseup .keyboard-table-cell': 'dehighlightBlurredKey'
      'click .keyboard-table-cell.editable': 'insertValue'
      'blur': 'dehighlightAllKeys'
      'focus .keyboard-table-cell': 'stopFocusPropagation'


  # Keyboard Field Display View
  # ---------------------------
  #
  # A view for displaying the `keyboard` attribute (an object) of Keyboards
  # models.

  class KeyboardFieldDisplayView extends FieldDisplayView

    fieldDisplayLabelContainerClass: 'dative-field-display-label-container top'
    fieldDisplayRepresentationContainerClass:
      'dative-field-display-representation-container full-width html-snippet'

    getRepresentationView: ->
      new KeyboardRepresentationView @context

    interceptKey: (event) ->
      super event
      @stopEvent event

    getValueFromDOM: ->

