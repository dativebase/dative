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

    events:
      'dialogdragstart': 'closeAllTooltips'
      # BUG: for some reason if I use the following event listener, jQuery raises an
      # error: "Uncaught TypeError: Cannot read property 'apply' of undefined".
      # So I'm just using the 'click' attribute of the "Ok" button.
      # 'click .ok': 'dialogClose'

    render: ->
      @$el.append @template()
      @dialogify()
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
            text: 'Ok'
            class: 'ok dative-tooltip'
            click: =>
              @dialogClose()
        ]
        dialogClass: 'dative-alert-dialog-widget'
        title: 'Alert'
        width: 400
        create: =>
          @$('.dative-alert-dialog-target').first().find('button').attr('tabindex', 0)
            .end()
        open: =>

    tooltipify: ->
      @$('button.ok')
        .tooltip
          content: 'click here to show you understand'
          items: 'button'
          position:
            my: 'right-5 center'
            at: 'left center'
            collision: 'flipfit'

    focusAppropriateInput: ->
      @$('.ok').first().focus()

    dialogOpen: ->
      Backbone.trigger 'alert-dialog:open'
      @$('.dative-alert-dialog').first().dialog 'open'

    dialogClose: (event) ->
      @$('.dative-alert-dialog').first().dialog 'close'

    isOpen: -> @$('.dative-alert-dialog').first().dialog 'isOpen'

    toggle: ->
      if @isOpen()
        @dialogClose()
      else
        @dialogOpen()

