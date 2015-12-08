define [
  'backbone'
  './base'
  './../templates/alert-dialog'
], (Backbone, BaseView, alertDialogTemplate) ->

  # Alert Dialog View
  # -----------------
  #
  # This is a dialog box for alerting the user of something and possibly
  # getting input from them, typically to "Ok" or "Cancel" a decision. It is
  # modal, i.e., it disables the rest of the UI until closed.
  #
  # By passing certain options to `@dialogOpen`, you can control what buttons
  # and inputs are present in the alert and which events they trigger and on
  # what target.

  class AlertDialogView extends BaseView

    template: alertDialogTemplate

    initialize: ->
      @listenTo Backbone, 'alertDialog:toggle', @toggle
      @listenTo Backbone, 'openAlertDialog', @dialogOpen

    events:
      'dialogdragstart': 'closeAllTooltips'
      # BUG: for some reason if I use the following event listener, jQuery raises an
      # error: "Uncaught TypeError: Cannot read property 'apply' of undefined".
      # So I'm just using the 'click' attribute of the "Ok" button.
      # 'click .ok': 'dialogClose'
      'keydown': 'escapeKey'
      'click .ui-dialog-titlebar-close': 'closeButtonClicked'

    closeButtonClicked: (event) -> @triggerCancelEvent()

    escapeKey: (event) -> if event.which is 27 then @triggerCancelEvent()

    render: ->
      @$el.append @template()
      @$target = @$ '.dative-alert-dialog-target'
      @dialogify()
      @setupButtons()
      @focusOkButton()
      # @tooltipify()
      @

    # Transform the alert dialog HTML to a jQueryUI dialog box.
    dialogify: ->
      @$('.dative-alert-dialog').first().dialog
        modal: true
        hide: {effect: 'fade'}
        show: {effect: 'fade'}
        autoOpen: false
        appendTo: @$('.dative-alert-dialog-target').first()
        buttons: [
            text: 'Cancel All'
            class: 'cancel-all dative-tooltip'
            click: =>
              @dialogClose()
              @triggerCancelAllEvent()
          ,
            text: 'Ok All'
            class: 'ok-all dative-tooltip'
            click: =>
              @dialogClose()
              @triggerConfirmAllEvent()
          ,
            text: 'Cancel'
            class: 'cancel dative-tooltip'
            click: =>
              @dialogClose()
              @triggerCancelEvent()
          ,
            text: 'Ok'
            class: 'ok dative-tooltip'
            click: =>
              @dialogClose()
              @triggerConfirmEvent()
        ]
        dialogClass: 'dative-alert-dialog-widget'
        title: 'Alert'
        width: 400
        create: =>
          @fontAwesomateCloseIcon()
          @$('.dative-alert-dialog-target')
            .first().find('button').attr('tabindex', 0).end()
        open: ->

    tooltipify: ->
      @$('button.ok')
        .tooltip
          content: 'click here to show you understand'
          items: 'button'
          position:
            my: 'right-5 center'
            at: 'left center'
            collision: 'flipfit'

    focusOkButton: ->
      @$('.dative-alert-dialog-target button.ok').first().focus()

    focusCancelButton: ->
      @$('.dative-alert-dialog-target button.cancel').first().focus()

    getEventTarget: ->
      eventTarget = @eventTarget or Backbone
      @eventTarget = null
      eventTarget

    triggerConfirmEvent: ->
      if @confirmEvent
        confirmEvent = @confirmEvent
        @confirmEvent = null
        eventTarget = @getEventTarget()
        if @prompt
          @confirmArgument = @getPromptInput()
        if @confirmArgument
          eventTarget.trigger confirmEvent, @confirmArgument
          @confirmArgument = null
        else
          eventTarget.trigger confirmEvent
      @setPromptInput('')

    triggerCancelEvent: ->
      if @cancelEvent
        cancelEvent = @cancelEvent
        @cancelEvent = null
        eventTarget = @getEventTarget()
        if @cancelArgument
          eventTarget.trigger cancelEvent, @cancelArgument
          @cancelArgument = null
        else
          eventTarget.trigger cancelEvent
      @setPromptInput('')

    triggerCancelAllEvent: ->
      if @cancelAllEvent
        cancelAllEvent = @cancelAllEvent
        @cancelAllEvent = null
        eventTarget = @getEventTarget()
        eventTarget.trigger cancelAllEvent
      @setPromptInput('')

    triggerConfirmAllEvent: ->
      if @confirmAllEvent
        confirmAllEvent = @confirmAllEvent
        @confirmAllEvent = null
        eventTarget = @getEventTarget()
        eventTarget.trigger confirmAllEvent
      @setPromptInput('')

    triggerSpecialButtonEvent: ->
      if @specialButtonEvent
        specialButtonEvent = @specialButtonEvent
        @specialButtonEvent = null
        eventTarget = @getEventTarget()
        eventTarget.trigger specialButtonEvent
      @setPromptInput('')

    dialogOpen: (options) ->
      @prompt = false
      @$('.dative-alert-dialog textarea').hide()
      if options.text then @setText options.text
      @specialButton options
      if options.confirm then @showCancelButton() else @hideCancelButton()
      if options.prompt then @showPromptInput()
      if options.confirmEvent then @confirmEvent = options.confirmEvent
      if options.cancelEvent then @cancelEvent = options.cancelEvent
      if options.confirmArgument then @confirmArgument = options.confirmArgument
      if options.eventTarget then @eventTarget = options.eventTarget
      if options.cancelArgument then @cancelArgument = options.cancelArgument
      @setConfirmButtonText options.confirmButtonText
      @setCancelButtonText options.cancelButtonText
      @confirmAllButton options
      @cancelAllButton options
      focusButton = options.focusButton or 'cancel'
      Backbone.trigger 'alert-dialog:open'
      if focusButton is 'ok'
        @$('.dative-alert-dialog').on("dialogopen", => @focusOkButton())
      else
        @$('.dative-alert-dialog').on("dialogopen", => @focusCancelButton())
      @$('.dative-alert-dialog').first().dialog 'open'

    setConfirmButtonText: (confirmButtonText) ->
      if confirmButtonText
        @$('button.ok').button label: confirmButtonText
      else
        @$('button.ok').button label: 'Ok'

    setCancelButtonText: (cancelButtonText) ->
      if cancelButtonText
        @$('button.cancel').button label: cancelButtonText
      else
        @$('button.cancel').button label: 'Cancel'

    setConfirmAllButtonText: (confirmAllButtonText) ->
      if confirmAllButtonText
        @$('button.ok-all').button label: confirmAllButtonText
      else
        @$('button.ok-all').button label: 'Ok All'

    setCancelAllButtonText: (cancelAllButtonText) ->
      if cancelAllButtonText
        @$('button.cancel-all').button label: cancelAllButtonText
      else
        @$('button.cancel-all').button label: 'Cancel All'

    confirmAllButton: (options) ->
      if options.confirmAllEvent
        @confirmAllEvent = options.confirmAllEvent
        @setConfirmAllButtonText options.confirmAllButtonText
        @showConfirmAllButton()
      else
        @confirmAllEvent = null
        @hideConfirmAllButton()

    cancelAllButton: (options) ->
      if options.cancelAllEvent
        @cancelAllEvent = options.cancelAllEvent
        @showCancelAllButton()
        @setCancelAllButtonText options.cancelAllButtonText
      else
        @cancelAllEvent = null
        @hideCancelAllButton()

    specialButton: (options) ->
      if options.specialButtonEvent
        @specialButtonEvent = options.specialButtonEvent
        @specialButtonText = options.specialButtonText
        @addSpecialButton()
      else
        @destroySpecialButton()
        @specialButtonEvent = null
        @specialButtonText = null

    destroySpecialButton: ->
      buttons = @$('.dative-alert-dialog').first().dialog 'option', 'buttons'
      if buttons.length > 4
        @$('.dative-alert-dialog').first().dialog 'option', 'buttons', buttons[1..]

    addSpecialButton: ->
      buttons = @$('.dative-alert-dialog').first().dialog 'option', 'buttons'
      buttons.unshift
        click: =>
          @dialogClose()
          @triggerSpecialButtonEvent()
        text: @specialButtonText
      @$('.dative-alert-dialog').first().dialog 'option', 'buttons', buttons

    setupButtons: ->
      @hideCancelButton()
      @hideCancelAllButton()
      @hideConfirmAllButton()

    showCancelButton: ->
      @$('.dative-alert-dialog-target button.cancel').show()

    showPromptInput: ->
      @prompt = true
      @$('.dative-alert-dialog textarea').show()

    hideCancelButton: ->
      @$('.dative-alert-dialog-target button.cancel').hide()

    hideCancelAllButton: ->
      @$('.dative-alert-dialog-target button.cancel-all').hide()

    showCancelAllButton: ->
      @$('.dative-alert-dialog-target button.cancel-all').show()

    hideConfirmAllButton: ->
      @$('.dative-alert-dialog-target button.ok-all').hide()

    showConfirmAllButton: ->
      @$('.dative-alert-dialog-target button.ok-all').show()

    setText: (text) ->
      @$('.dative-alert-dialog-target .dative-alert-text').text text

    getPromptInput: () ->
      @$('.dative-alert-dialog textarea.dative-alert-prompt').val()

    setPromptInput: (value) ->
      @$('.dative-alert-dialog textarea.dative-alert-prompt').val value

    dialogClose: (event) ->
      @$('.dative-alert-dialog').first().dialog 'close'

    isOpen: -> @$('.dative-alert-dialog').first().dialog 'isOpen'

    toggle: ->
      if @isOpen()
        @dialogClose()
      else
        @dialogOpen()

