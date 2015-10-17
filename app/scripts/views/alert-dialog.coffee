define [
  'backbone'
  './base'
  './../templates/alert-dialog'
], (Backbone, BaseView, alertDialogTemplate) ->

  # AlertDialogView
  # ---------------
  #
  # This is a dialog box for alerting the user of something. It should disable
  # rest of the UI until the user clicks "Ok" or some such thing.

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
          @$('.dative-alert-dialog-target').first().find('button').attr('tabindex', 0)
            .end()
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
        eventTarget = @getEventTarget()
        if @prompt
          @confirmArgument = @getPromptInput()
        if @confirmArgument
          eventTarget.trigger @confirmEvent, @confirmArgument
          @confirmArgument = null
        else
          eventTarget.trigger @confirmEvent
        @confirmEvent = null
      @setPromptInput('')

    triggerCancelEvent: ->
      if @cancelEvent
        eventTarget = @getEventTarget()
        if @cancelArgument
          eventTarget.trigger @cancelEvent, @cancelArgument
          @confirmArgument = null
        else
          eventTarget.trigger @cancelEvent
        @cancelEvent = null
      @setPromptInput('')

    dialogOpen: (options) ->
      @prompt = false
      @$('.dative-alert-dialog input').hide()

      if options.text then @setText options.text
      if options.confirm then @showCancelButton()
      if options.prompt then @showPromptInput()
      if options.confirmEvent then @confirmEvent = options.confirmEvent
      if options.cancelEvent then @cancelEvent = options.cancelEvent
      if options.confirmArgument then @confirmArgument = options.confirmArgument
      if options.eventTarget
        @eventTarget = options.eventTarget
      if options.cancelArgument then @cancelArgument = options.cancelArgument
      focusButton = options.focusButton or 'cancel'
      Backbone.trigger 'alert-dialog:open'
      if focusButton is 'ok'
        @$('.dative-alert-dialog').on("dialogopen", => @focusOkButton())
      else
        @$('.dative-alert-dialog').on("dialogopen", => @focusCancelButton())
      @$('.dative-alert-dialog').first().dialog 'open'

    setupButtons: ->
      @hideCancelButton()

    showCancelButton: ->
      @$('.dative-alert-dialog-target button.cancel').show()

    showPromptInput: ->
      @prompt = true
      guessPromptType = @getPromptText()
      if not guessPromptType
       guessPromptType = 'text'
      else if guessPromptType.indexOf('number') > -1
       guessPromptType = 'number'
      else if guessPromptType.indexOf('password') > -1
       guessPromptType = 'password'
      else if guessPromptType.indexOf('date') > -1 || guessPromptType.indexOf('day') > -1 || guessPromptType.indexOf('when') > -1 
       guessPromptType = 'date'
      else
        guessPromptType = 'text'
      @$('.dative-alert-dialog input').attr 'type', guessPromptType
      @$('.dative-alert-dialog input').show()

    hideCancelButton: ->
      @$('.dative-alert-dialog-target button.cancel').hide()

    setText: (text) ->
      @$('.dative-alert-dialog-target .dative-alert-text').text text
    
    getPromptText: (text) ->
      @$('.dative-alert-dialog-target .dative-alert-text').text() || ""

    getPromptInput: () ->
      @$('.dative-alert-dialog input.dative-alert-prompt').val()

    setPromptInput: (value) ->
      @$('.dative-alert-dialog input.dative-alert-prompt').val value

    dialogClose: (event) ->
      @$('.dative-alert-dialog').first().dialog 'close'

    isOpen: -> @$('.dative-alert-dialog').first().dialog 'isOpen'

    toggle: ->
      if @isOpen()
        @dialogClose()
      else
        @dialogOpen()

