define [
  './input'
  './../utils/globals'
  './../templates/keyboard-input'
], (InputView, globals, keyboardTemplate) ->

  # Keyboard Input View
  # -------------------
  #
  # A view for an interface for configuring keyboards. This interface displays
  # a visual representation of a keyboard and allows the user to alter how the
  # keys behave. The user can also test this behaviour either by typing into a
  # specific field or clicking the buttons/keys of the keyboard representation.

  class KeyboardInputView extends InputView

    template: keyboardTemplate

    initialize: (@context) ->

      # The model's 'keyboard' attribute is our keyboard map. It maps key codes
      # to objects that encode how a particular keycode should behave, given
      # what meta keys are being pressed simultaneously.
      @keyboardMap = @model.get 'keyboard'

      @keyboardLayout = @getKeyboardLayout()
      @context.keyboardLayout = @keyboardLayout

      # Callback var holds the id of the response to a setTimeout call. If a
      # double-click event occurs on a visual keyboard key, then the handler
      # will call `clearTimeout` on this var to prevent the single-click
      # insertion of the key's character/string.
      @cbVar1 = null
      @cbVar2 = null

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
      keyboardLayout = @updateKeyboardLayoutWithModelKeyboard keyboardLayout
      @updateKeyboardLayoutWithUnicodeMetadata keyboardLayout

    # Update our `keyboardLayout` object so that its metadata object contains
    # an array of strings that contain Unicode metadata about all of the
    # values/representations for each key.
    updateKeyboardLayoutWithUnicodeMetadata: (keyboardLayout) ->
      for coord, meta of keyboardLayout.coord2meta
        if meta.editable
          unicodeMetadata = []
          for repr in meta.repr
            if repr
              unicodeMetadata.push @unicodeMetadata(repr)
            else
              unicodeMetadata.push null
          meta.unicodeMetadata = unicodeMetadata
      keyboardLayout

    # Update our `keyboardLayout` object so that its key representations match
    # the mappings in `@keyboardMap`
    updateKeyboardLayoutWithModelKeyboard: (keyboardLayout) ->
      for keycode, keyMap of @keyboardMap
        coord = keyboardLayout.keycode2coord[keycode]
        if coord
          if keyMap.default
            keyboardLayout.coord2meta[coord].repr[0] = keyMap.default
          if keyMap.shift
            keyboardLayout.coord2meta[coord].repr[1] = keyMap.shift
          if keyMap.alt
            keyboardLayout.coord2meta[coord].repr[2] = keyMap.alt
          if keyMap.altshift
            keyboardLayout.coord2meta[coord].repr[3] = keyMap.altshift
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
      'mousedown .keyboard-table-cell': 'highlightFocusedKey'
      'mouseup .keyboard-table-cell': 'dehighlightBlurredKey'
      'click .keyboard-table-cell.editable': 'insertValue'
      'dblclick .keyboard-table-cell.editable': 'displayKeyEditInterface'
      'keydown .key-mapping-value': 'maybeHideKeyInterface'
      'input .key-mapping-value': 'keyMappingChanged'
      'click .hide-key-map-table': 'hideKeyInterface'
      'blur': 'dehighlightAllKeys'
      'focus .keyboard-table-cell': 'stopFocusPropagation'

    # Logic elsewhere in this view handles modification of the
    # `@model.get('keyboard')` object based on user actions. We return `null`
    # here because we don't want an object with 'default' and 'shift'
    # attributes to be set to the model. The only thing we alter is the
    # `keyboard` object.
    getValueFromDOM: -> null

    refresh: (@context) ->
      console.log 'keyboard input is being asked to refresh'
      @initialize @context
      @render()

    stopFocusPropagation: (event) ->
      @stopEvent event

    # If user enters Esc or Enter in key interface, we hide it.
    maybeHideKeyInterface: (event) ->
      if event.which in [27, 13]
        @stopEvent event
        @hideKeyInterface()

    # User has changed the value that corresponds to a given key in a given
    # mode (i.e., default, shift, etc.). So, we update `@model.get('keyboard')`
    # and we update the interface accordingly.
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
      @updateKeyboardLayoutWithModelKeyboard @keyboardLayout
      @updateKeyboardLayoutWithUnicodeMetadata @keyboardLayout
      @model.trigger 'change'

    # The default mapping for a key is `null` for every "mode".
    defaultKeyMap:
      default: null
      shift: null # shiftKey
      alt: null # altKey
      altshift: null # altKey and shiftKey

    # Display the interface for editing how a specific key behaves when the
    # user clicks it.
    displayKeyEditInterface: (event) ->
      if @cbVar1
        clearTimeout @cbVar1
        @cbVar1 = null
      if @cbVar2
        clearTimeout @cbVar2
        @cbVar2 = null
      @turnOffEditModeAll()
      @setKeyToEditMode event
      @stopEvent event
      $key = @$ event.currentTarget
      keyCoord = $key.data 'coord'
      keycode = @keyboardLayout.coord2keycode[keyCoord]
      keyMap = @keyboardMap[keycode]
      keyRepr = @keyboardLayout.coord2meta[keyCoord].repr
      if not keyMap
        keyMap = @keyboardMap[keycode] = @utils.clone @defaultKeyMap
      @renderKeyInterface keyMap, keycode, keyRepr
      @showKeyInterface()

    # Make the key edit interface contain the representation of the key that is
    # encoded by `keyMap`, `keycode`, and `keyRepr`.
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
      @$('textarea.key-mapping-value').first().focus()

    hideKeyInterface: ->
      @$('.key-map-interface').hide()
      @turnOffEditModeAll()

    setKeyToEditMode: (event) ->
      @$(event.currentTarget).addClass 'dative-shadowed-widget key-edit-mode'

    highlightFocusedKey: (event) ->
      @$(event.currentTarget).addClass 'ui-state-highlight'

    # User has single-clicked on a key so we insert the corresponding
    # char/string into the .key-mapping-value textarea. The complication is to
    # avoid inserting on a double-click; this is the reason for the
    # instance-bound timeout-ed callbacks below.
    insertValue: (event) ->
      $key = @$ event.currentTarget
      keyCoord = $key.data 'coord'
      keycode = @keyboardLayout.coord2keycode[keyCoord]
      keyMap = @keyboardMap[keycode]
      $target = @$ '.keyboard-test-input'
      if keyMap
        values = [keyMap.default, keyMap.shift, keyMap.alt, keyMap.altshift]
      else
        values = @keyboardLayout.coord2meta[keyCoord]?.repr
      value = null
      if values
        if event.shiftKey
          if event.altKey
            value = values[3]
          else
            value = values[1]
        else if event.altKey
          value = values[2]
        else
          value = values[0]
      if value
        cb = =>
          @stopEvent event
          $target.val($target.val() + value)
          clearTimeout @cbVar1
          clearTimeout @cbVar2
          @cbVar1 = @cbVar2 = null
        if @cbVar1
          @cbVar2 = setTimeout cb, 500
        else
          @cbVar1 = setTimeout cb, 500
      $target.focus()

    dehighlightBlurredKey: (event) ->
      @$(event.currentTarget).removeClass 'ui-state-highlight'

    dehighlightAllKeys: ->
      @$('.keyboard-table-cell').removeClass 'ui-state-highlight'

    turnOffEditModeAll: ->
      @$('.keyboard-table-cell').removeClass 'dative-shadowed-widget key-edit-mode'

    # The user has issued a keydown event from their physical keyboard while
    # the .keyboard-test-input textarea was in focus. We intercept this event
    # and insert our custom keyboard value into the textrea, if we have such a
    # value in this keyboard resource.
    interceptKey: (event) ->
      @highlightKeyByKeycode event
      keyMap = @keyboardMap[event.which]
      $target = @$ '.keyboard-test-input'
      value = null
      if keyMap
        if event.shiftKey
          if event.altKey
            value = keyMap.altshift
          else
            value = keyMap.shift
        else if event.altKey
          value = keyMap.alt
        else
          value = keyMap.default
      if value
        @stopEvent event
        $target.val($target.val() + value)

    # The user has issued a keydown/keyup event using their physical keyboard.
    # We change what characters/strings our visual keyboard is displaying. This
    # method makes it so that when the user holds down, e.g., the shift key,
    # the "shift-mode" characters are displayed.
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

    resetTooltips: (modeIndex) ->
      @$('.keyboard-table-cell.editable').each (i, e) =>
        $e = @$ e
        coord = $e.data 'coord'
        unicode = @keyboardLayout.coord2meta[coord].unicodeMetadata[modeIndex]
        if unicode then unicode = "#{unicode}. " else unicode = ''
        $e.tooltip content: "#{unicode}Double-click to edit."

    showDefaultReprs: ->
      @$('.key-repr').hide()
      @resetTooltips 0
      @$('.keyboard-cell-repr').show()

    showAltShiftReprs: ->
      @$('.key-repr').hide()
      @resetTooltips 3
      @$('.keyboard-cell-alt-shift-repr').show()

    showShiftReprs: ->
      @$('.key-repr').hide()
      @resetTooltips 1
      @$('.keyboard-cell-shift-repr').show()

    showAltReprs: ->
      @$('.key-repr').hide()
      @resetTooltips 2
      @$('.keyboard-cell-alt-repr').show()

    highlightKeyByKeycode: (event) ->
      @showKeyReprsByMode event
      coord = @keyboardLayout.keycode2coord[event.which]
      if coord
        @$(".coord-#{coord}").addClass 'ui-state-highlight'

    dehighlightKeyByKeycode: (event) ->
      @showKeyReprsByMode event
      # Command key on Mac behaves strangely in that it prevents keyup events
      # from firing when those events correspond to key pressed when command is
      # held down: here we detect it by key code and dehighlight all keys if
      # a keyup is fired on it.
      if event.which in [91, 93]
        @dehighlightAllKeys()
      else
        coord = @keyboardLayout.keycode2coord[event.which]
        if coord then @$(".coord-#{coord}").removeClass 'ui-state-highlight'

    # Make the border colors match the jQueryUI theme.
    bordercolorify: ->
      @$('textarea, input, .keyboard-table-cell, .key-map-table')
        .css "border-color", @constructor.jQueryUIColors().defBo

    # Return a string that encodes the Unicode metadata of `string`. In
    # particular, the metadata string lists the code points and names of the
    # Unicode characters in `string`.
    unicodeMetadata: (string) ->
      meta = []
      string = string.normalize 'NFD'
      for char in string
        codePoint = @utils.decimal2hex(char.charCodeAt(0)).toUpperCase()
        try
          name = globals.unicodeCharMap[codePoint] or 'Name unknown'
        catch
          name = 'Name unknown'
        meta.push "U+#{codePoint} (#{name})"
      meta.join ', '

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
      coord2meta:

        '0-0': editable: false, repr: ['esc', 'esc', null, null]
        # Must hold down Apple "fn" key to get the following codes
        '0-1': editable: true, repr: ['F1', null, null, null]
        '0-2': editable: true, repr: ['F2', null, null, null]
        '0-3': editable: true, repr: ['F3', null, null, null]
        '0-4': editable: true, repr: ['F4', null, null, null]
        '0-5': editable: true, repr: ['F5', null, null, null]
        '0-6': editable: true, repr: ['F6', null, null, null]
        '0-7': editable: true, repr: ['F7', null, null, null]
        '0-8': editable: true, repr: ['F8', null, null, null]
        '0-9': editable: true, repr: ['F9', null, null, null]
        '0-10': editable: true, repr: ['F10', null, null, null]
        '0-11': editable: false, repr: ['F11', null, null, null]
        '0-12': editable: false, repr: ['F12', null, null, null]
        '0-13': editable: false, repr: ['', '', null, null]

        '1-0': editable: true, repr: ['`', '~', null, null]
        '1-1': editable: true, repr: ['1', '!', null, null]
        '1-2': editable: true, repr: ['2', '@', null, null]
        '1-3': editable: true, repr: ['3', '#', null, null]
        '1-4': editable: true, repr: ['4', '$', null, null]
        '1-5': editable: true, repr: ['5', '%', null, null]
        '1-6': editable: true, repr: ['6', '^', null, null]
        '1-7': editable: true, repr: ['7', '&', null, null]
        '1-8': editable: true, repr: ['8', '*', null, null]
        '1-9': editable: true, repr: ['9', '(', null, null]
        '1-10': editable: true, repr: ['0', ')', null, null]
        '1-11': editable: true, repr: ['-', '_', null, null]
        '1-12': editable: true, repr: ['=', '+', null, null]
        '1-13': editable: false, repr: ['delete', 'delete', null, null]

        '2-0': editable: false, repr: ['tab', 'tab', null, null]
        '2-1': editable: true, repr: ['q', 'Q', null, null]
        '2-2': editable: true, repr: ['w', 'W', null, null]
        '2-3': editable: true, repr: ['e', 'E', null, null]
        '2-4': editable: true, repr: ['r', 'R', null, null]
        '2-5': editable: true, repr: ['t', 'T', null, null]
        '2-6': editable: true, repr: ['y', 'Y', null, null]
        '2-7': editable: true, repr: ['u', 'U', null, null]
        '2-8': editable: true, repr: ['i', 'I', null, null]
        '2-9': editable: true, repr: ['o', 'O', null, null]
        '2-10': editable: true, repr: ['p', 'P', null, null]
        '2-11': editable: true, repr: ['[', '{', null, null]
        '2-12': editable: true, repr: [']', '}', null, null]
        '2-13': editable: true, repr: ['\\', '|', null, null]

        '3-0': editable: false, repr: ['caps lock', 'caps lock', null, null]
        '3-1': editable: true, repr: ['a', 'A', null, null]
        '3-2': editable: true, repr: ['s', 'S', null, null]
        '3-3': editable: true, repr: ['d', 'D', null, null]
        '3-4': editable: true, repr: ['f', 'F', null, null]
        '3-5': editable: true, repr: ['g', 'G', null, null]
        '3-6': editable: true, repr: ['h', 'H', null, null]
        '3-7': editable: true, repr: ['j', 'J', null, null]
        '3-8': editable: true, repr: ['k', 'K', null, null]
        '3-9': editable: true, repr: ['l', 'L', null, null]
        '3-10': editable: true, repr: [';', ':', null, null]
        '3-11': editable: true, repr: ["'", '"', null, null]
        '3-12': editable: false, repr: ['return', 'enter', null, null]

        '4-0': editable: false, repr: ['shift', 'shift', null, null]
        '4-1': editable: true, repr: ['z', 'Z', null, null]
        '4-2': editable: true, repr: ['x', 'X', null, null]
        '4-3': editable: true, repr: ['c', 'C', null, null]
        '4-4': editable: true, repr: ['v', 'V', null, null]
        '4-5': editable: true, repr: ['b', 'B', null, null]
        '4-6': editable: true, repr: ['n', 'N', null, null]
        '4-7': editable: true, repr: ['m', 'M', null, null]
        '4-8': editable: true, repr: [',', '<', null, null]
        '4-9': editable: true, repr: ['.', '>', null, null]
        '4-10': editable: true, repr: ['/', '?', null, null]
        '4-11': editable: false, repr: ['shift', 'shift', null, null]

        '5-0': editable: false, repr: ['fn', 'fn', null, null] # Apple fn key
        '5-1': editable: false, repr: ['control', 'control', null, null]
        '5-2': editable: false, repr: ['alt', 'alt', null, null]
        '5-3': editable: false, repr: ['command', 'command', null, null]
        '5-4': editable: false, repr: [' ', ' ', null, null]
        '5-5': editable: false, repr: ['command', 'command', null, null]
        '5-6': editable: false, repr: ['alt', 'alt', null, null]
        '5-7': editable: false, repr: ['◀', '◀', null, null]
        '5-8-0': editable: false, repr: ['▲', '▲', null, null]
        '5-8-1': editable: false, repr: ['▼', '▼', null, null]
        '5-9': editable: false, repr: ['▶', '▶', null, null]

