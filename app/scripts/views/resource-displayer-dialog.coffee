define [
  'backbone'
  './base'
  './../templates/resource-displayer-dialog'
], (Backbone, BaseView, resourceDisplayerDialogTemplate) ->

  # Resource Displayer Dialog View
  # ------------------------------
  #
  # A view (based on jQueryUI's dialog) for displaying a single resource, e.g.,
  # a search, or a form.

  class ResourceDisplayerDialogView extends BaseView

    template: resourceDisplayerDialogTemplate
    timestamp: 0

    initialize: (options) ->
      @index = options?.index or 1
      @atTop = false
      @resourceView = null
      @setDimensions()
      @listenTo Backbone, 'resourceDisplayerDialog:toggle', @toggle
      @listenTo Backbone, 'resourceDisplayerDialog:show', @showResourceView
      @listenTo Backbone, 'resourceDisplayerDialog:moveToBottom', @moveToBottom

    setDimensions: ->
      @lastPosition = @defaultPosition()
      @lastWidth = null
      @lastHeight = null
      $window = $ window
      windowWidth = $window.width()
      @width = windowWidth * 0.333
      @maxWidth = windowWidth * 0.75
      windowHeight = $window.height()
      @height = windowHeight * 0.333
      @maxHeight = windowHeight * 0.75

    events:
      'click .minimize': 'minimize'
      'click .maximize': 'maximize'
      'dblclick .ui-resizable-se': 'trueMaximize'
      'mousedown': 'moveToTop'

    render: ->
      @$el.append @template()
      @$target = @$ '.dative-resource-displayer-dialog-target' # outer DIV to which jQueryUI dialog appends
      @dialogify()
      @addTitleButtons()
      @guify()
      @$('div.resource-displayer-content-container')
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
      @$('.dative-resource-displayer-dialog')
        .dialog 'option',
          title: @getResourceViewTitle()
          height: height
          position: @lastPosition
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
        @$('.dative-resource-displayer-dialog')
          .dialog 'option', 'width', width
        if not @resourceView.model.get('id')
          @resourceView.$('.update-resource').click()
      setTimeout x, 500

    spinnerOptions: ->
      _.extend BaseView::spinnerOptions(), {top: '5%', left: '5%'}

    spin: -> @$('.resource-displayer-content').spin @spinnerOptions()

    stopSpin: -> @$('.resource-displayer-content').spin false

    # Transform the resource displayer dialog HTML to a jQueryUI dialog box.
    dialogify: ->
      @$('.dative-resource-displayer-dialog').dialog(
        stack: false
        position: @defaultPosition()
        hide: {effect: 'fade'}
        show: {effect: 'fade'}
        autoOpen: false
        appendTo: @$('.dative-resource-displayer-dialog-target')
        buttons: []
        dialogClass: 'dative-resource-displayer-dialog-widget
          dative-shadowed-widget'
        title: 'Resource Displayer'
        width: @width
        height: @height
        maxHeight: @maxHeight
        create: =>
          @fontAwesomateCloseIcon()
        close: =>
          if @resourceView
            @resourceView.close()
            @closed @resourceView
            @resourceView = null
          @closeAllTooltips()
          @timestamp = 0
        open: (event, ui) =>
          @moveToTop()
        resizeStart: =>
          $dialogContent = @$ '.ui-dialog-content'
          if not $dialogContent.is(':visible')
            $dialogContent.show()
        resizeStop: (event, ui) =>
          @lastWidth = ui.size.width
          @lastHeight = ui.size.height
          @lastPosition =
            my: "left+#{ui.position.left} top+#{ui.position.top}"
            at: "left top"
            of: window
        dragStart: => @closeAllTooltips()
        dragStop: (event, ui) =>
          @lastPosition =
            my: "left+#{ui.position.left} top+#{ui.position.top}"
            at: "left top"
            of: window
      )

    moveToTop: ->
      @atTop = true
      Backbone.trigger 'resourceDisplayerDialog:moveToBottom'
      @$('.ui-dialog').css 'z-index', 110

    moveToBottom: ->
      if @atTop
        @atTop = false
      else
        @$('.ui-dialog').css 'z-index', 100


    # Reduce the dialog to just its title bar and place it in the bottom right
    # corner of the window.
    minimize: ->
      @closeAllTooltips()
      @$('.ui-dialog-content').hide()
      @$('.dative-resource-displayer-dialog')
        .dialog "option",
          height: 15
          width: $(window).width() * 0.24
          position: @minimizedPosition()

    # Expand the dialog to its last dimensions and place it in its last
    # location.
    maximize: ->
      @$('.ui-dialog-content').show()
      [height, width] = @getResourceDimensions()
      if @lastHeight then height = @lastHeight
      if @lastWidth then width = @lastWidth
      @$('.dative-resource-displayer-dialog')
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
      @$('.dative-resource-displayer-dialog')
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

    defaultPosition: ->
      offset = (@index - 1) * 30
      my: 'right bottom'
      at: "right-#{offset} bottom-#{offset}"
      of: window

    minimizedPosition: ->
      offset = (@index - 1) * 25
      my: 'right bottom'
      at: "right-#{offset}% bottom"
      of: window

    guify: ->
      @$('button.dialog-header-button')
        .button()
        .tooltip()
      @$('button.ui-dialog-titlebar-close').tooltip()

    # Add the maximize and minimize buttons to the titlebar.
    addTitleButtons: ->
      @$('.dative-resource-displayer-dialog-widget')
        .children(".ui-dialog-titlebar")
        .append("<button class='dialog-header-button minimize dative-tooltip'
                         title='Minimize and place at bottom'>
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

    dialogOpen: ->
      Backbone.trigger 'resource-displayer-dialog:open'
      @$('.dative-resource-displayer-dialog').dialog 'open'

    dialogClose: -> @$('.dative-resource-displayer-dialog').dialog 'close'

    isOpen: -> @$('.dative-resource-displayer-dialog').dialog 'isOpen'

    toggle: (options) ->
      if @isOpen()
        @dialogClose()
      else
        @dialogOpen()

