define [
  './input'
  './../templates/keyboard-input'
], (InputView, keyboardTemplate) ->

  # Keyboard Input View
  # -------------------
  #
  # A view for a data input field that is a textarea for writing phonology
  # keyboards.

  class KeyboardInputView extends InputView

    template: keyboardTemplate

    initialize: (@context) ->

      # The 'keyboard' attribute is our keyboard map. It maps key codes to
      # objects that encode how a particular keycode should behave, given what
      # meta keys are being pressed simultaneously.
      @keyboardMap = @model.get 'keyboard'

      @keyboardLayout = @getKeyboardLayout()
      @context.keyboardLayout = @keyboardLayout

    render: ->
      @$el.html @template(@context)
      @guify()
      @listenToEvents()
      @

    guify: ->
      @bordercolorify()
      @autosize()
      @buttonify()
      @tooltipify()

    buttonify: ->
      @$('button').button()

    tooltipify: ->
      @$('.dative-tooltip').tooltip()

    listenToEvents: ->
      super
      @listenTo @model, 'updateKeyboardSuccess', @updateKeyboardSuccess

    # When an update succeeds, our model's keyboard attribute will be a new
    # object so we need to update `@keyboardMap` to resolve to it.
    updateKeyboardSuccess: ->
      @keyboardMap = @model.get 'keyboard'

    getKeyboardLayout: ->
      # For now, we are just supporting "the" (i.e., my) Apple laptop keyboard
      # layout
      # TODO: the model should allow the user to specify a keyboard layout from
      # a fixed list. Then Dative must be able to understand and implement an
      # interface to that type of layout.
      keyboardLayout = @appleKeyboardLayout()
      keyboardLayout = @addKeycode2coord keyboardLayout
      @updateKeyboardLayoutWithModelKeyboard keyboardLayout

    # Update our `keyboardLayout` object so that its key representations match
    # the mappings in `@keyboardMap`
    updateKeyboardLayoutWithModelKeyboard: (keyboardLayout) ->
      for keycode, keyMap of @keyboardMap
        coord = keyboardLayout.keycode2coord[keycode]
        if coord
          if keyMap.default
            keyboardLayout.coord2repr[coord][0] = keyMap.default
          if keyMap.shift
            keyboardLayout.coord2repr[coord][1] = keyMap.shift
      keyboardLayout

    # Dynamically create an object that maps JavaScript key codes to the
    # coordinates of the appropriate keys in the keyboard table.
    addKeycode2coord: (keyboardLayout) ->
      keyboardLayout.keycode2coord = {}
      for coord, keycode of keyboardLayout.coord2keycode
        if keycode
          keyboardLayout.keycode2coord[keycode] = coord
      keyboardLayout

    events:
      'keydown': 'highlightKeyByKeycode'
      'keydown .keyboard-test-input': 'interceptKey'
      'keyup': 'dehighlightKeyByKeycode'
      'focus .keyboard-table-cell': 'highlightFocusedKey'
      'blur .keyboard-table-cell': 'dehighlightBlurredKey'
      'dblclick .keyboard-table-cell': 'displayKeyEditInterface'
      'input .key-mapping-value': 'keyMappingChanged'
      'click .hide-key-map-table': 'hideKeyInterface'

    keyMappingChanged: (event) ->
      $textarea = @$ event.currentTarget
      keycode = $textarea.data 'keycode'
      mode = $textarea.attr 'name'
      value = $textarea.val()
      keyMap = @keyboardMap[keycode]
      if not keyMap
        keyMap = @keyboardMap[keycode] = @utils.clone @defaultKeyMap
      keyMap[mode] = value
      coord = @keyboardLayout.keycode2coord[keycode]
      if coord
        selector = ".keyboard-table-cell.coord-#{coord}"
        if keyMap.default isnt null
          @$(selector).find('.keyboard-cell-repr').text keyMap.default
        if keyMap.shift isnt null
          @$(selector).find('.keyboard-cell-shift-repr').text keyMap.shift
        if keyMap.alt isnt null
          @$(selector).find('.keyboard-cell-alt-repr').text keyMap.alt
        if keyMap.altshift isnt null
          @$(selector).find('.keyboard-cell-alt-shift-repr').text keyMap.altshift
      else
      @updateKeyboardLayoutWithModelKeyboard @keyboardLayout

    defaultKeyMap:
      default: null
      shift: null # shiftKey
      alt: null # altKey
      altshift: null # altKey and shiftKey
      # ctrl: null # ctrlKey; TODO: allow user to override these? ...
      # meta: null # metaKey; TODO: allow user to override these? ...

    displayKeyEditInterface: (event) ->
      @turnOffEditModeAll()
      @setKeyToEditMode event
      @stopEvent event
      $key = @$ event.currentTarget
      keyCoord = $key.data 'coord'
      keycode = @keyboardLayout.coord2keycode[keyCoord]
      keyMap = @keyboardMap[keycode]
      keyRepr = @keyboardLayout.coord2repr[keyCoord]
      if not keyMap
        keyMap = @keyboardMap[keycode] = @utils.clone @defaultKeyMap
      @renderKeyInterface keyMap, keycode, keyRepr
      @showKeyInterface()

    renderKeyInterface: (keyMap, keycode, keyRepr) ->
      @$('.key-map-table-keycode').text keycode
      for mode, value of keyMap
        if value
          @$("textarea[name=#{mode}]").val value
            .data 'keycode', keycode
        else
          @$("textarea[name=#{mode}]").val ''
            .data 'keycode', keycode

    showKeyInterface: (keyMap) ->
      @$('.key-map-interface').show()

    hideKeyInterface: ->
      @$('.key-map-interface').hide()
      @turnOffEditModeAll()

    setKeyToEditMode: (event) ->
      @$(event.currentTarget).addClass 'dative-shadowed-widget'

    highlightFocusedKey: (focusEvent) ->
      @$(focusEvent.currentTarget).addClass 'ui-state-highlight'

    dehighlightBlurredKey: (blurEvent) ->
      @$(blurEvent.currentTarget).removeClass 'ui-state-highlight'

    dehighlightAllKeys: ->
      @$('.keyboard-table-cell').removeClass 'ui-state-highlight'

    turnOffEditModeAll: ->
      @$('.keyboard-table-cell').removeClass 'dative-shadowed-widget'

    interceptKey: (event) ->
      @highlightKeyByKeycode event
      keyMap = @keyboardMap[event.which]
      $target = @$ '.keyboard-test-input'
      if keyMap
        if event.shiftKey
          if event.altKey
            if keyMap.altshift
              @stopEvent event
              $target.val($target.val() + keyMap.altshift)
          else
            if keyMap.shift
              @stopEvent event
              $target.val($target.val() + keyMap.shift)
        else if event.altKey
          if keyMap.alt
            @stopEvent event
            $target.val($target.val() + keyMap.alt)
        else
          if keyMap.default
            @stopEvent event
            $target.val($target.val() + keyMap.default)

    showKeyReprsByMode: (event) ->
      if event.shiftKey
        if event.altKey
          @showAltShiftReprs()
        else
          @showShiftReprs()
      else if event.altKey
        @showAltReprs()
      else
        @showDefaultReprs()

    showDefaultReprs: ->
      @$('.key-repr').hide()
      @$('.keyboard-cell-repr').show()

    showAltShiftReprs: ->
      @$('.key-repr').hide()
      @$('.keyboard-cell-alt-shift-repr').show()

    showShiftReprs: ->
      @$('.key-repr').hide()
      @$('.keyboard-cell-shift-repr').show()

    showAltReprs: ->
      @$('.key-repr').hide()
      @$('.keyboard-cell-alt-repr').show()

    highlightKeyByKeycode: (event) ->
      @showKeyReprsByMode event
      coord = @keyboardLayout.keycode2coord[event.which]
      if coord
        @$(".coord-#{coord}").addClass 'ui-state-highlight'

    dehighlightKeyByKeycode: (event) ->
      @showKeyReprsByMode event
      coord = @keyboardLayout.keycode2coord[event.which]
      if coord
        @$(".coord-#{coord}").removeClass 'ui-state-highlight'

    # Make the border colors match the jQueryUI theme.
    bordercolorify: ->
      @$('textarea, input, .keyboard-table-cell, .key-map-table')
        .css "border-color", @constructor.jQueryUIColors().defBo

    ############################################################################
    # Apple laptop keyboard layout dimensions
    ############################################################################
    #
    # The height and width dimension values given here are in inches. The
    # template converts them to pixels using the `ppi` (pixels per inch)
    # attribute.

    appleFunctionKeyDimensions:
      height: 0.375 # 3/8"
      width: 0.6875 # 11/16"

    appleDefaultKeyDimensions:
      height: 0.625 # 5/8"
      width: 0.625 # 5/8"

    appleBottomRowKeyDimensions:
      height: 0.75 # 6/8"
      width: 0.625 # 5/8"

    # Returns an object representing an Apple Macbook-style keyboard. (There
    # may be many, this one looks like the one I use.)
    appleKeyboardLayout: ->

      # Each value represents how many keys are in that row.
      rows: [
        14
        14
        14
        13
        12
        10
      ]

      defaultDimensions: @appleDefaultKeyDimensions

      ppi: 48 # pixels per inch (really, it's 96, but that's too big)

      # Maps key co-ordinates to dimensions of the physical keys
      dimensions:
        '0-0': @appleFunctionKeyDimensions
        '0-1': @appleFunctionKeyDimensions
        '0-2': @appleFunctionKeyDimensions
        '0-3': @appleFunctionKeyDimensions
        '0-4': @appleFunctionKeyDimensions
        '0-5': @appleFunctionKeyDimensions
        '0-6': @appleFunctionKeyDimensions
        '0-7': @appleFunctionKeyDimensions
        '0-8': @appleFunctionKeyDimensions
        '0-9': @appleFunctionKeyDimensions
        '0-10': @appleFunctionKeyDimensions
        '0-11': @appleFunctionKeyDimensions
        '0-12': @appleFunctionKeyDimensions
        '0-13': @appleFunctionKeyDimensions
        '1-13': {width: 1.0, height: 0.625}
        '2-0': {width: 1.0, height: 0.625}
        '3-0': {width: 1.1875, height: 0.625}
        '3-12': {width: 1.1875, height: 0.625}
        '4-0': {width: 1.5625, height: 0.625}
        '4-11': {width: 1.5625, height: 0.625}
        '5-0': @appleBottomRowKeyDimensions
        '5-1': @appleBottomRowKeyDimensions
        '5-2': @appleBottomRowKeyDimensions
        '5-3': {width: 0.8125, height: 0.75}
        '5-4': {width: 3.625, height: 0.75}
        '5-5': {width: 0.8125, height: 0.75}
        '5-6': @appleBottomRowKeyDimensions
        '5-7': @appleFunctionKeyDimensions
        # An array of dimensions is represented as a key container containing
        # multiple keys of the given dimensions.
        '5-8': [@appleFunctionKeyDimensions, @appleFunctionKeyDimensions]
        '5-9': @appleFunctionKeyDimensions

      # Maps key coordinates (row-col) to JavaScript key codes.
      coord2keycode:

        '0-0': 27
        # Must hold down Apple "fn" key to get the following codes
        '0-1': 112
        '0-2': 113
        '0-3': 114
        '0-4': 115
        '0-5': 116
        '0-6': 117
        '0-7': 118
        '0-8': 119
        '0-9': 120
        '0-10': 121
        '0-11': null
        '0-12': null
        '0-13': null

        '1-0': 192
        '1-1': 49
        '1-2': 50
        '1-3': 51
        '1-4': 52
        '1-5': 53
        '1-6': 54
        '1-7': 55
        '1-8': 56
        '1-9': 57
        '1-10': 48
        '1-11': 189
        '1-12': 187
        '1-13': 8

        '2-0': 9
        '2-1': 81
        '2-2': 87
        '2-3': 69
        '2-4': 82
        '2-5': 84
        '2-6': 89
        '2-7': 85
        '2-8': 73
        '2-9': 79
        '2-10': 80
        '2-11': 219
        '2-12': 221
        '2-13': 220

        '3-0': 20
        '3-1': 65
        '3-2': 83
        '3-3': 68
        '3-4': 70
        '3-5': 71
        '3-6': 72
        '3-7': 74
        '3-8': 75
        '3-9': 76
        '3-10': 186
        '3-11': 222
        '3-12': 13

        '4-0': 16
        '4-1': 90
        '4-2': 88
        '4-3': 67
        '4-4': 86
        '4-5': 66
        '4-6': 78
        '4-7': 77
        '4-8': 188
        '4-9': 190
        '4-10': 191
        '4-11': 16

        '5-0': null # Apple fn key
        '5-1': 17
        '5-2': 18
        '5-3': 91
        '5-4': 32
        '5-5': 93
        '5-6': 18
        '5-7': 37
        '5-8-0': 38
        '5-8-1': 40
        '5-9': 39

      # Maps key coordinates (row-col) to representations of the default
      # values, i.e., characters, corresponding to the key at the specified
      # coordinates. The representations are 4-tuple arrays where the elements
      # are:
      # 1. the default value/repr
      # 2. the with-shift value/repr
      # 3. the with-alt value/repr
      # 4. the with-alt+shift value/repr
      coord2repr:

        '0-0': ['esc', null, null, null]
        # Must hold down Apple "fn" key to get the following codes
        '0-1': ['F1', null, null, null]
        '0-2': ['F2', null, null, null]
        '0-3': ['F3', null, null, null]
        '0-4': ['F4', null, null, null]
        '0-5': ['F5', null, null, null]
        '0-6': ['F6', null, null, null]
        '0-7': ['F7', null, null, null]
        '0-8': ['F8', null, null, null]
        '0-9': ['F9', null, null, null]
        '0-10': ['F10', null, null, null]
        '0-11': ['F11', null, null, null]
        '0-12': ['F12', null, null, null]
        '0-13': ['', null, null, null]

        '1-0': ['`', '~', null, null]
        '1-1': ['1', '!', null, null]
        '1-2': ['2', '@', null, null]
        '1-3': ['3', '#', null, null]
        '1-4': ['4', '$', null, null]
        '1-5': ['5', '%', null, null]
        '1-6': ['6', '^', null, null]
        '1-7': ['7', '&', null, null]
        '1-8': ['8', '*', null, null]
        '1-9': ['9', '(', null, null]
        '1-10': ['0', ')', null, null]
        '1-11': ['-', '_', null, null]
        '1-12': ['=', '+', null, null]
        '1-13': ['delete', null, null, null]

        '2-0': ['tab', null, null, null]
        '2-1': ['q', 'Q', null, null]
        '2-2': ['w', 'W', null, null]
        '2-3': ['e', 'E', null, null]
        '2-4': ['r', 'R', null, null]
        '2-5': ['t', 'T', null, null]
        '2-6': ['y', 'Y', null, null]
        '2-7': ['u', 'U', null, null]
        '2-8': ['i', 'I', null, null]
        '2-9': ['o', 'O', null, null]
        '2-10': ['p', 'P', null, null]
        '2-11': ['[', '{', null, null]
        '2-12': [']', '}', null, null]
        '2-13': ['\\', '|', null, null]

        '3-0': ['caps lock', null, null, null]
        '3-1': ['a', 'A', null, null]
        '3-2': ['s', 'S', null, null]
        '3-3': ['d', 'D', null, null]
        '3-4': ['f', 'F', null, null]
        '3-5': ['g', 'G', null, null]
        '3-6': ['h', 'H', null, null]
        '3-7': ['j', 'J', null, null]
        '3-8': ['k', 'K', null, null]
        '3-9': ['l', 'L', null, null]
        '3-10': [';', ':', null, null]
        '3-11': ["'", '"', null, null]
        '3-12': ['return', 'enter', null, null]

        '4-0': ['shift', null, null, null]
        '4-1': ['z', 'Z', null, null]
        '4-2': ['x', 'X', null, null]
        '4-3': ['c', 'C', null, null]
        '4-4': ['v', 'V', null, null]
        '4-5': ['b', 'B', null, null]
        '4-6': ['n', 'N', null, null]
        '4-7': ['m', 'M', null, null]
        '4-8': [',', '<', null, null]
        '4-9': ['.', '>', null, null]
        '4-10': ['/', '?', null, null]
        '4-11': ['shift', null, null, null]

        '5-0': ['fn', null, null, null] # Apple fn key
        '5-1': ['control', null, null, null]
        '5-2': ['option', 'alt', null, null]
        '5-3': ['command', '⌘', null, null]
        '5-4': [' ', null, null, null]
        '5-5': ['command', '⌘', null, null]
        '5-6': ['option', 'alt', null, null]
        '5-7': ['◀', null, null, null]
        '5-8-0': ['▲', null, null, null]
        '5-8-1': ['▼', null, null, null]
        '5-9': ['▶', null, null, null]

