define [
  './base'
  './../templates/exporter-dialog'
  'perfectscrollbar'
], (BaseView, exporterDialogTemplate) ->

  # Exporter Dialog View
  # --------------------
  #
  # This is a jQueryUI dialog that contains the interface for choosing export
  # options and displaying the export of a form or a collection of forms.

  class ExporterDialogView extends BaseView

    template: exporterDialogTemplate

    initialize: ->
      @hasBeenRendered = false
      @listenTo Backbone, 'exporterDialog:toggle', @toggle
      @listenTo Backbone, 'exporterDialog:openTo', @openTo

    events:
      'dialogdragstart': 'closeAllTooltips'

    render: ->
      @hasBeenRendered = true
      @$el.append @template()
      @$target = @$ '.dative-exporter-dialog-target'
      @dialogify()
      @guify()
      @

    # Transform the help dialog HTML to a jQueryUI dialog box.
    dialogify: ->
      height = $(window).height() * 0.8
      width = $(window).width() * 0.6
      @$('.dative-exporter-dialog').dialog
        modal: true
        position: @defaultPosition()
        hide: {effect: 'fade'}
        show: {effect: 'fade'}
        autoOpen: false
        appendTo: @$('.dative-exporter-dialog-target')
        buttons: []
        dialogClass: 'dative-exporter-dialog-widget'
        title: 'Export'
        width: width
        height: height
        create: =>
          @fontAwesomateCloseIcon()
        close: =>
          @closeAllTooltips()

    defaultPosition: ->
      my: "center"
      at: "center"
      of: @$target.first().parent().parent()

    guify: ->

    setToBeExported: (options) ->
      @model = options.model
      @collection = options.collection
      @toBeExported = @model or @collection

    generateExport: ->
      $contentContainer = @$ '.dative-exporter-dialog-content'
      if @model
        content = "<pre>#{@getModelAsFormattedJSON @model}</pre>"
      else if @collection
        content = "<pre>#{@getCollectionAsFormattedJSON @collection}</pre>"
      else
        content = 'Sorry, unable to generate an export.'
      $contentContainer.html content

    getModelAsFormattedJSON: (model) ->
      modelObject = @model.toJSON()
      delete modelObject.collection
      JSON.stringify modelObject, undefined, 4

    getCollectionAsFormattedJSON: (collection) ->
      collectionArray = @collection.toJSON()
      modelArray = []
      for modelObject in collectionArray
        delete modelObject.collection
        modelArray.push modelObject
      JSON.stringify modelArray, undefined, 4

    dialogOpen: ->
      @$('.dative-exporter-dialog').dialog 'open'

    dialogClose: -> @$('.dative-exporter-dialog').dialog 'close'

    isOpen: -> @$('.dative-exporter-dialog').dialog 'isOpen'

    toggle: (options) ->
      if not @hasBeenRendered
        @render()
      if @isOpen()
        @dialogClose()
      else
        @dialogOpen()

    spinnerOptions: ->
      _.extend BaseView::spinnerOptions(), {top: '5%', left: '5%'}

    spin: -> @$('.dative-exporter-dialog-content').spin @spinnerOptions()

    stopSpin: -> @$('.dative-exporter-dialog-content').spin false

