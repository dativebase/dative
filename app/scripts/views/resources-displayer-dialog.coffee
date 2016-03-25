define [
  'backbone'
  './dialog-base'
  './../templates/resources-displayer-dialog'
], (Backbone, DialogBaseView, resourcesDisplayerDialogTemplate) ->

  # Resources Displayer Dialog View
  # -------------------------------
  #
  # A view (based on jQueryUI's dialog) for displaying a collection of
  # resources, e.g., all forms. This view allows users to browse resources of
  # type X while still viewing something else in the main window.

  class ResourcesDisplayerDialogView extends DialogBaseView

    template: resourcesDisplayerDialogTemplate
    timestamp: 0

    # This is the class selector of the <div> in the template that becomes
    # dialogified.
    getDialogClassSelector: -> '.dative-resources-displayer-dialog'

    # This is a class name that should be passed in as the value of the
    # `.dialog` method's `dialogClass` param. It will be a class name in the
    # .ui-dialog.ui-widget <div> that holds everything.
    getDialogWidgetClass: -> 'dative-resources-displayer-dialog-widget'

    getWidth: (windowWidth) -> windowWidth * 0.75
    getMaxWidth: (windowWidth) -> windowWidth * 0.95
    getHeight: (windowHeight) -> windowHeight * 0.75
    getMaxHeight: (windowHeight) -> windowHeight * 0.95

    initialize: (options) ->
      @atTop = false
      @resourcesView = null
      @setDimensions()

      @listenTo Backbone, 'resourcesDisplayerDialog:toggle', @toggle
      @listenTo Backbone, 'resourcesDisplayerDialog:show', @showResourcesView
      @listenTo Backbone, 'resourcesDisplayerDialog:moveToBottom', @moveToBottom

    # We override `DialogBaseView`'s events object because we add two new
    # events.
    events:
      'click .minimize': 'minimize'
      'click .maximize': 'maximize'
      'dblclick .ui-resizable-se': 'trueMaximize'
      'mousedown': 'moveToTop'

    render: ->
      @$el.append @template()
      @$target = @$ '.dative-resources-displayer-dialog-target' # outer DIV to which jQueryUI dialog appends
      @dialogify()
      @addHeaderButtons()
      @guify()
      @$(@getDialogClassSelector())
        .first().scroll => @closeAllTooltips()
      @

    getResourcesViewTitle: ->
      @resourcesView.resourceNamePluralHuman

    # Show the supplied resources view in this dialog and make the dialog
    # visible. `resourcesView` should be a Backbone view over resources with a
    # collection.
    showResourcesView: (resourcesView) ->
      @timestamp = new Date().getTime()
      if @resourcesView
        @resourcesView.close()
        @closed @resourcesView
      @resourcesView = resourcesView
      if not @isOpen() then @dialogOpen()
      height = if @lastHeight then @lastHeight else @height
      title = @getResourcesViewTitle()
      @$(@getDialogClassSelector())
        .dialog 'option',
          title: title
          height: height
          position: @lastPosition
      @moveToTop()
      # We wait between dialogifying and rendering the resources in the dialog;
      # this seems to be necessary in order to get the width of the contained
      # resource.
      x = =>
        @resourcesView.setElement @$('#appview-dialog')
        @resourcesView.render()
        @rendered @resourcesView
        [height, width] = @getResourceDimensions()
        if @lastWidth then width = @lastWidth
        @$(@getDialogClassSelector())
          .dialog 'option', 'width', width
      setTimeout x, 500

    closeFully: ->
      @closeInner()
      @dialogClose()

    spinnerOptions: ->
      _.extend BaseView::spinnerOptions(), {top: '5%', left: '5%'}

    spin: -> @$('#appview-dialog').spin @spinnerOptions()

    stopSpin: -> @$('#appview-dialog').spin false

    # Transform the resource displayer dialog HTML to a jQueryUI dialog box.
    dialogify: ->
      @$(@getDialogClassSelector()).dialog(
        stack: false
        position: @defaultPosition()
        hide: {effect: 'fade'}
        show: {effect: 'fade'}
        autoOpen: false
        appendTo: @$('.dative-resources-displayer-dialog-target')
        buttons: []
        dialogClass: "#{@getDialogWidgetClass()} dative-shadowed-widget"
        title: 'Resources Displayer'
        width: @width
        maxWidth: @maxWidth
        height: @height
        maxHeight: @maxHeight
        create: =>
          @fontAwesomateCloseIcon()
        close: =>
          @closeInner()
        open: (event, ui) =>
          @moveToTop()
        resizeStart: =>
          $dialogContent = @$ '.ui-dialog-content'
          if not $dialogContent.is(':visible')
            $dialogContent.show()
        resizeStop: (event, ui) => @resizeStop event, ui
        dragStart: => @closeAllTooltips()
        dragStop: (event, ui) => @dragStop event, ui
      )

    closeInner: ->
      console.log 'closeInner called'
      if @resourcesView
        @resourcesView.close()
        @closed @resourcesView
        @resourcesView = null
      @closeAllTooltips()
      @timestamp = 0

    # Move the dialog to the top of the stack via its z-index CSS.
    moveToTop: ->
      @atTop = true
      Backbone.trigger 'resourcesDisplayerDialog:moveToBottom'
      @$('.ui-dialog').css 'z-index', 110

    # Move the dialog to the bottom of the stack via its z-index CSS.
    moveToBottom: ->
      if @atTop
        @atTop = false
      else
        @$('.ui-dialog').css 'z-index', 100

    # Expand the dialog to its last dimensions and place it in its last
    # location. NOTE: we override the `DialogBaseView`'s method because we want
    # to use the dimensions of the resource we contain, not the max dimensions.
    maximize: ->
      @$('.ui-dialog-content').show()
      [height, width] = @getResourceDimensions()
      if @lastHeight then height = @lastHeight
      if @lastWidth then width = @lastWidth
      @$(@getDialogClassSelector())
        .dialog "option",
          position: @lastPosition
          height: height
          width: width

    # By double-clicking on the bottom right resize corner, the dialog will
    # expand to the size of the resource that it contains, if that size is not
    # greater than the maxima.
    trueMaximize: ->
      [height, width] = @getResourceDimensions()
      @lastWidth = width
      @lastHeight = height
      @$(@getDialogClassSelector())
        .dialog "option",
          height: height
          width: width

    # Get the dimentions of the resource being displayed in this dialog.
    getResourceDimensions: ->
      height = @resourcesView.$el.height() + 80
      width = @resourcesView.$el.width() + 40
      if height > @maxHeight then height = @maxHeight
      if width > @maxWidth then width = @maxWidth
      [height, width]

    # Default position of a resource displayer dialog depends on its index,
    # i.e., which one of the N resource displayers this is.
    defaultPosition: ->
      my: 'right bottom'
      at: "right bottom"
      of: window

    # Minimized position of a resource displayer dialog depends on its index,
    # i.e., which one of the N resource displayers this is.
    minimizedPosition: ->
      my: 'right bottom'
      at: 'right bottom'
      of: window

    guify: -> @guifyHeaderButtons()

    dialogOpen: ->
      Backbone.trigger 'resources-displayer-dialog:open'
      @$(@getDialogClassSelector()).dialog 'open'

    dialogClose: -> @$(@getDialogClassSelector()).dialog 'close'

    isOpen: -> @$(@getDialogClassSelector()).dialog 'isOpen'

    toggle: (options) ->
      if @isOpen()
        @dialogClose()
      else
        @dialogOpen()


