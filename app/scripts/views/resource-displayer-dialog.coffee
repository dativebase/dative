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

    initialize: ->
      $window = $ window
      @width = $window.width() * 0.333
      @height = $window.height() * 0.333
      @maxHeight = $window.height() * 0.75
      @listenTo Backbone, 'resourceDisplayerDialog:toggle', @toggle
      @listenTo Backbone, 'resourceDisplayerDialog:show', @showResourceView

    events:
      'dialogdragstart': 'closeAllTooltips'
      'click .minimize': 'minimize'
      'click .maximize': 'maximize'

    render: ->
      @$el.append @template()
      @$target = @$ '.dative-resource-displayer-dialog-target'
      @dialogify()
      @addTitleButtons()
      @guify()
      @$('div.resource-displayer-content-container')
        .first().scroll => @closeAllTooltips()
      @

    spinnerOptions: ->
      _.extend BaseView::spinnerOptions(), {top: '5%', left: '5%'}

    spin: -> @$('.resource-displayer-content').spin @spinnerOptions()

    stopSpin: -> @$('.resource-displayer-content').spin false

    # Transform the resource displayer dialog HTML to a jQueryUI dialog box.
    dialogify: ->
      @$('.dative-resource-displayer-dialog').dialog(
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
          @closeAllTooltips()
        resizeStart: =>
          $dialogContent = @$ '.ui-dialog-content'
          if not $dialogContent.is(':visible')
            $dialogContent.show()
      )

    minimize: ->
      @$('.ui-dialog-content').hide()
      @$('.dative-resource-displayer-dialog')
        .dialog "option",
          height: 15
          position: @minimizedPosition()

    maximize: ->
      @$('.ui-dialog-content').show()
      @$('.dative-resource-displayer-dialog')
        .dialog "option",
          position: @defaultPosition()
          height: @getDialogHeight()
          width: @width

    defaultPosition: ->
      my: 'left center'
      at: 'left center'
      of: window

    minimizedPosition: ->
      my: "left bottom"
      at: "left bottom"
      of: window

    guify: ->
      @$('button.dialog-header-button')
        .button()
        .tooltip()
      @$('button.ui-dialog-titlebar-close').tooltip()

    addTitleButtons: ->
      @$('.dative-resource-displayer-dialog-widget')
        .children(".ui-dialog-titlebar")
        .append("<button class='dialog-header-button minimize dative-tooltip'
                         title='Minimize and place at bottom left'>
                   <i class='fa fa-fw fa-minus'
                      style='position: relative;
                             right: 0.38em; bottom: 0.25em;'></i>
                 </button>
                 <button class='dialog-header-button maximize dative-tooltip'
                         title='Revert to standard position and size'
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

    showResourceView: (resourceView, $target) ->
      @resourceView = resourceView
      if not @isOpen() then @dialogOpen()
      @resourceView.expanded = true
      @resourceView.dataLabelsVisible = true
      @resourceView.effectuateExpanded()
      @$('.resource-displayer-content')
        .html @resourceView.render().el
      @$('.dative-resource-displayer-dialog')
        .dialog 'option',
          title: "#{@resourceView.resourceName}"
          height: @getDialogHeight()
          position: @defaultPosition()

    getDialogHeight: ->
      @$('.ui-dialog-content').show()
      idealHeight = @resourceView.$el.height() + 80
      if idealHeight > @maxHeight
        @maxHeight
      else
        idealHeight

