define [
  'backbone'
  './dialog-base'
  './../templates/resource-displayer-dialog'
], (Backbone, DialogBaseView, resourceDisplayerDialogTemplate) ->

  # Resource Displayer Dialog View
  # ------------------------------
  #
  # A view (based on jQueryUI's dialog) for displaying a single resource, e.g.,
  # a search, or a form.

  class ResourceDisplayerDialogView extends DialogBaseView

    template: resourceDisplayerDialogTemplate
    timestamp: 0

    # This is the class selector of the <div> in the template that becomes
    # dialogified.
    getDialogClassSelector: -> '.dative-resource-displayer-dialog'

    # This is a class name that should be passed in as the value of the
    # `.dialog` method's `dialogClass` param. It will be a class name in the
    # .ui-dialog.ui-widget <div> that holds everything.
    getDialogWidgetClass: -> 'dative-resource-displayer-dialog-widget'

    initialize: (options) ->
      @index = options?.index or 1
      @atTop = false
      @resourceView = null
      @setDimensions()
      @listenTo Backbone, 'resourceDisplayerDialog:toggle', @toggle
      @listenTo Backbone, 'resourceDisplayerDialog:show', @showResourceView
      @listenTo Backbone, 'resourceDisplayerDialog:moveToBottom', @moveToBottom

    # We override `DialogBaseView`'s events object because we add two new
    # events.
    events:
      'click .minimize': 'minimize'
      'click .maximize': 'maximize'
      'dblclick .ui-resizable-se': 'trueMaximize'
      'mousedown': 'moveToTop'

    render: ->
      @$el.append @template()
      @$target = @$ '.dative-resource-displayer-dialog-target' # outer DIV to which jQueryUI dialog appends
      @dialogify()
      @addHeaderButtons()
      @guify()
      @$(@getDialogClassSelector())
        .first().scroll => @closeAllTooltips()
      @

    getResourceViewTitle: ->
      if @resourceView.model.get('id')
        "#{@utils.capitalize @resourceView.resourceNameHumanReadable()}
          ##{@resourceView.model.get('id')}"
      else
        "New #{@resourceView.resourceNameHumanReadable()}"

    # Show the supplied resource view in this dialog and make the dialog
    # visible. `resourceView` should be a Backbone view with a model.
    showResourceView: (resourceView) ->
      @timestamp = new Date().getTime()
      if @resourceView
        @resourceView.close()
        @closed @resourceView
      @resourceView = resourceView
      if not @isOpen() then @dialogOpen()
      @resourceView.expanded = true
      @resourceView.dataLabelsVisible = true
      @resourceView.effectuateExpanded()
      height = if @lastHeight then @lastHeight else @height
      title = @getResourceViewTitle()
      @$(@getDialogClassSelector())
        .dialog 'option',
          title: @getResourceViewTitle()
          height: height
          position: @lastPosition
      @listenForModification()
      @moveToTop()
      # We wait between dialogifying and rendering the resource in the dialog;
      # this seems to be necessary in order to get the width of the contained
      # resource.
      x = =>
        @$('.resource-displayer-content')
          .html @resourceView.render().el
        @rendered @resourceView
        [height, width] = @getResourceDimensions()
        if @lastWidth then width = @lastWidth
        @$(@getDialogClassSelector())
          .dialog 'option', 'width', width
        if not @resourceView.model.get('id')
          @resourceView.$('.update-resource').click()
      setTimeout x, 500

    listenForModification: ->

      @listenTo @resourceView.model,
        "add#{@resourceView.resourceNameCapitalized}Success",
        @closeFully

      @listenTo @resourceView.model,
        "update#{@resourceView.resourceNameCapitalized}Success",
        @closeFully

      @listenTo @resourceView.model,
        "destroy#{@resourceView.resourceNameCapitalized}Success",
        @closeFully

    closeFully: ->
      @closeInner()
      @dialogClose()

    spinnerOptions: ->
      _.extend BaseView::spinnerOptions(), {top: '5%', left: '5%'}

    spin: -> @$('.resource-displayer-content').spin @spinnerOptions()

    stopSpin: -> @$('.resource-displayer-content').spin false

    # Transform the resource displayer dialog HTML to a jQueryUI dialog box.
    dialogify: ->
      @$(@getDialogClassSelector()).dialog(
        stack: false
        position: @defaultPosition()
        hide: {effect: 'fade'}
        show: {effect: 'fade'}
        autoOpen: false
        appendTo: @$('.dative-resource-displayer-dialog-target')
        buttons: []
        dialogClass: "#{@getDialogWidgetClass()} dative-shadowed-widget"
        title: 'Resource Displayer'
        width: @width
        maxWidth: @maxWidth
        height: @height
        maxHeight: @maxHeight
        create: =>
          @fontAwesomateCloseIcon()
        close: => @closeInner()
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
      if @resourceView
        @stopListening @resourceView.model
        @resourceView.close()
        @closed @resourceView
        @resourceView = null
      @closeAllTooltips()
      @timestamp = 0

    # Move the dialog to the top of the stack via its z-index CSS.
    moveToTop: ->
      @atTop = true
      Backbone.trigger 'resourceDisplayerDialog:moveToBottom'
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
      height = @resourceView.$el.height() + 80
      width = @resourceView.$el.width() + 40
      if height > @maxHeight then height = @maxHeight
      if width > @maxWidth then width = @maxWidth
      [height, width]

    # Default position of a resource displayer dialog depends on its index,
    # i.e., which one of the N resource displayers this is.
    defaultPosition: ->
      offset = (@index - 1) * 30
      my: 'right bottom'
      at: "right-#{offset} bottom-#{offset}"
      of: window

    # Minimized position of a resource displayer dialog depends on its index,
    # i.e., which one of the N resource displayers this is.
    minimizedPosition: ->
      offset = (@index - 1) * 25
      my: 'right bottom'
      at: "right-#{offset}% bottom"
      of: window

    guify: -> @guifyHeaderButtons()

    dialogOpen: ->
      Backbone.trigger 'resource-displayer-dialog:open'
      @$(@getDialogClassSelector()).dialog 'open'

    dialogClose: -> @$(@getDialogClassSelector()).dialog 'close'

    isOpen: -> @$(@getDialogClassSelector()).dialog 'isOpen'

    toggle: (options) ->
      if @isOpen()
        @dialogClose()
      else
        @dialogOpen()

