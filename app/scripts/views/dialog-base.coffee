define [
  'backbone'
  './base'
  './../templates/resource-displayer-dialog'
], (Backbone, BaseView, resourceDisplayerDialogTemplate) ->

  # Dialog Base View
  # ----------------
  #
  # A view that other views should/may sub-class if they are based on jQueryUI's
  # dialog.
  #
  # This view provides logic for adding minimize and maximize buttons to the
  # dialog's titlebar and for reacting to user interaction with those buttons.
  # The dialog's last position and dimensions are remembered so that they can
  # be restored when the maximize button is clicked. See the
  # `ResourceDisplayerDialogView` for a class that sub-classes this one.

  class DialogBaseView extends BaseView

    initialize: (options) ->
      @atTop = false

    # This is the class selector of the <div> in the template that becomes
    # dialogified.
    getDialogClassSelector: -> '. ...'

    # This is a class name that should be passed in as the value of the
    # `.dialog` method's `dialogClass` param. It will be a class name in the
    # .ui-dialog.ui-widget <div> that holds everything.
    getDialogWidgetClass: -> ''

    setDimensions: ->
      @lastPosition = @defaultPosition()
      @lastWidth = null
      @lastHeight = null
      $window = $ window
      windowWidth = $window.width()
      windowHeight = $window.height()
      @width = @getWidth windowWidth
      @minWidth = @getMinWidth windowWidth
      @minimizedWidth = @getMinimizedWidth windowWidth
      @maxWidth = @getMaxWidth windowWidth
      @height = @getHeight windowHeight
      @minimizedHeight = @getMinimizedHeight windowHeight
      @maxHeight = @getMaxHeight windowHeight

    getWidth: (windowWidth) -> windowWidth * 0.333
    getMinWidth: (windowWidth) -> windowWidth * 0.24
    getMinimizedWidth: (windowWidth) -> windowWidth * 0.24
    getMaxWidth: (windowWidth) -> windowWidth * 0.75

    getHeight: (windowHeight) -> windowHeight * 0.333
    getMinHeight: (windowHeight) -> 15
    getMinimizedHeight: (windowHeight) -> 15
    getMaxHeight: (windowHeight) -> windowHeight * 0.75

    getMaximizedPosition: -> @lastPosition

    events:
      'click .minimize': 'minimize'
      'click .maximize': 'maximize'

    # This is the method that should be passed to the dialog constructor's
    # `resizeStop` option.
    resizeStop: (event, ui) ->
      @lastWidth = ui.size.width
      @lastHeight = ui.size.height
      @lastPosition =
        my: "left+#{ui.position.left} top+#{ui.position.top}"
        at: "left top"
        of: window

    # This is the method that should be passed to the dialog constructor's
    # `dragStop` option.
    dragStop: (event, ui) ->
      @lastPosition =
        my: "left+#{ui.position.left} top+#{ui.position.top}"
        at: "left top"
        of: window

    # Reduce the dialog to just its title bar and place it in the bottom right
    # corner of the window.
    minimize: ->
      @closeAllTooltips()
      @$('.ui-dialog-content').hide()
      @$(@getDialogClassSelector())
        .dialog "option",
          height: @minimizedHeight
          width: @minimizedWidth
          position: @minimizedPosition()
      @minimizePost()

    minimizePost: ->

    # Override this in sub-classes to change the minimized position of the
    # dialog.
    minimizedPosition: ->
      my: 'right bottom'
      at: 'right bottom'
      of: window

    # Expand the dialog to its previous dimensions (or, failing that, max
    # dimensions) and place it in its last location.
    maximize: ->
      @$('.ui-dialog-content').show()
      if @lastHeight
        height = @lastHeight
      else
        height = @maxHeight
      if @lastWidth
        width = @lastWidth
      else
        width = @maxWidth
      @$(@getDialogClassSelector())
        .dialog "option",
          position: @getMaximizedPosition()
          height: height
          width: width
      @maximizePost()

    maximizePost: ->

    # Add the maximize and minimize buttons to the titlebar.
    addHeaderButtons: ->
      @$(".#{@getDialogWidgetClass()}")
        .children(".ui-dialog-titlebar")
        .append("<button class='dialog-header-button minimize dative-tooltip'
                         title='Minimize and set aside'>
                   <i class='fa fa-fw fa-minus'
                      style='position: relative;
                             right: 0.38em; bottom: 0.25em;'></i>
                 </button>
                 <button class='dialog-header-button maximize dative-tooltip'
                         title='Revert to last position and size (or standard ones)'
                         style='margin-right: 0.25em'>
                   <i class='fa fa-fw fa-expand'
                      style='position: relative;
                             right: 0.38em; bottom: 0.25em;'></i>
                 </button>")

    guifyHeaderButtons: ->
      @$('button.dialog-header-button')
        .button()
        .tooltip()
      @$('button.ui-dialog-titlebar-close').tooltip()

    # Override this in sub-classes to change the default position of the dialog.
    defaultPosition: ->
      my: 'right bottom'
      at: 'right bottom'
      of: window

    # Move the dialog to the top of the stack via its z-index CSS.
    moveToTop: ->
      @atTop = true
      Backbone.trigger 'dialogs:moveToBottom'
      @$('.ui-dialog').css 'z-index', 110

    # Move the dialog to the bottom of the stack via its z-index CSS.
    moveToBottom: ->
      if @atTop
        @atTop = false
      else
        @$('.ui-dialog').css 'z-index', 100

