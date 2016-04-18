define [
  './keyboard'
  './keyboard-field-display'
  './keyboard-input'
], (KeyboardView, KeyboardFieldDisplayView, KeyboardInputView) ->

  # TODO: rename this stuff from "EventBased-" to "EventBased-"

  class EventBasedKeyboardRepresentationView extends KeyboardInputView

    # AppView broadcasts system-wide keydown/keyup events via our model. This
    # allows us to react to the user holding down the shift and/or alt keys.
    listenToEvents: ->
      super
      @listenTo @model, 'systemWideKeydown', @systemWideKeydown
      @listenTo @model, 'systemWideKeyup', @systemWideKeyup

    systemWideKeydown: (event) ->
      @highlightKeyByKeycode event

    systemWideKeyup: (event) ->
      @dehighlightKeyByKeycode event

    # This is what makes this keybaord event-based. When you click on it, it
    # sends out Backbone-wide keyboard keydown events indicating which
    # character/string should be input. Then inputs can listen to these events
    # and respond accordingly.
    insertValue: (event) ->
      $key = @$ event.currentTarget
      keyCoord = $key.data 'coord'
      keycode = @keyboardLayout.coord2keycode[keyCoord]
      keyMap = @keyboardMap[keycode]
      $target = @$ '.keyboard-test-input'
      reprs = @keyboardLayout.coord2meta[keyCoord]?.repr
      if keyMap
        values = [keyMap.default, keyMap.shift, keyMap.alt, keyMap.altshift]
      else
        values = reprs
      value = null
      if values
        if event.shiftKey
          if event.altKey
            value = values[3] or reprs[3]
          else
            value = values[1] or reprs[1]
        else if event.altKey
          value = values[2] or reprs[2]
        else
          value = values[0] or reprs[0]
      if value then Backbone.trigger 'keyboardValue', value

    initialize: (@context) ->
      super @context
      @context.editable = false

    events:
      'keydown': 'highlightKeyByKeycode'
      'keyup': 'dehighlightKeyByKeycode'
      'mousedown .keyboard-table-cell': 'highlightFocusedKey'
      'mouseup .keyboard-table-cell': 'dehighlightBlurredKey'
      'click .keyboard-table-cell.editable': 'insertValue'
      'blur': 'dehighlightAllKeys'
      'focus .keyboard-table-cell': 'stopFocusPropagation'

    render: ->
      super
      # We don't need a test input because we are sending and receiving signals
      # to/from the input that we are bound to.
      @$('.keyboard-test-input-container').hide()
      @


  class EventBasedKeyboardFieldDisplayView extends KeyboardFieldDisplayView

    getRepresentationView: ->
      new EventBasedKeyboardRepresentationView @context

    render: ->
      super
      # We don't need a label saying "keyboard" either.
      @$('label[for=keyboard]').hide()
      @


  # Event-based Keyboard View
  # -------------------------
  #
  # A subclass of `KeyboardView` which is designed so that when a user clicks
  # on its keys it triggers events which can be received by a particular field.
  # This effectively makes the keyboard work as a clickable keyboard interface.

  class EventBasedKeyboardView extends KeyboardView

    # Set labels to always visible so that the labels button will not be
    # rendered.
    initialize: (options) ->
      options.labelsAlwaysVisible = true
      super options

    # We don't need no stinking actions.
    excludedActions: [
      'history'
      'controls'
      'data'
      'settings'
      'update'
      'delete'
      'export'
      'duplicate'
    ]

    # We only show the keyboard's keyboard attribute.
    primaryAttributes: ['keyboard']
    secondaryAttributes: []

    attribute2displayView:
      keyboard: EventBasedKeyboardFieldDisplayView

