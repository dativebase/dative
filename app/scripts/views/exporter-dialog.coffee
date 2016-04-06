define [
  './base'
  './exporter-collection-csv'
  './exporter-json'
  './exporter-simple-interlinear-glosses-wordpress'
  './exporter-ids'
  './exporter-latex'
  './dialog-base'
  './../templates/exporter-dialog'
], (BaseView, ExporterCollectionCSVView, ExporterJSONView,
  ExporterSIGPluginView, ExporterIdsView, ExporterLaTeXView, DialogBaseView,
  exporterDialogTemplate) ->


  # This view exports collection models only, i.e., texts, as LaTeX.
  # The definition of the new class is a necessary hack so that collections of
  # collections do not display LaTeX as an export format option.

  class ExporterLaTeXCollectionModelView extends ExporterLaTeXView

    exportTypes: -> ['model']
    exportResources: -> ['collection']


  # Exporter Dialog View
  # --------------------
  #
  # This is a jQueryUI dialog that contains the interface for interacting with
  # various exporters that can be used to export various types of data.

  class ExporterDialogView extends BaseView

    registeredExporterClasses: [
      ExporterCollectionCSVView
      ExporterLaTeXView
      ExporterLaTeXCollectionModelView
      ExporterJSONView
      ExporterSIGPluginView
      ExporterIdsView
    ]

    template: exporterDialogTemplate

    initialize: ->
      @atTop = false
      @getExporterViews()
      @hasBeenRendered = false
      @moveToTop = DialogBaseView::moveToTop
      @moveToBottom = DialogBaseView::moveToBottom
      @listenTo Backbone, 'exporterDialog:toggle', @toggle
      @listenTo Backbone, 'exporterDialog:openTo', @openTo
      @listenTo Backbone, 'dialogs:moveToBottom', @moveToBottom

    events:
      'dialogdragstart': 'closeAllTooltips'
      'mousedown': 'moveToTop'

    render: ->
      @hasBeenRendered = true
      @$el.append @template()
      @$target = @$ '.dative-exporter-dialog-target'
      @dialogify()
      @renderExporterViews()
      @guify()
      @

    getExporterViews: ->
      @exporterViews = []
      for exporterClass in @registeredExporterClasses
        exporterView = new exporterClass()
        @exporterViews.push exporterView

    renderExporterViews: ->
      fragment = document.createDocumentFragment()
      for exporterView in @exporterViews
        fragment.appendChild exporterView.render().el
        @rendered exporterView
      @$('.dative-exporter-dialog-exporters').html fragment

    # Transform the help dialog HTML to a jQueryUI dialog box.
    dialogify: ->
      height = $(window).height() * 0.8
      width = $(window).width() * 0.6
      @$('.dative-exporter-dialog').dialog
        # modal: true
        position: @defaultPosition()
        hide: {effect: 'fade'}
        show: {effect: 'fade'}
        autoOpen: false
        appendTo: @$('.dative-exporter-dialog-target')
        dialogClass: 'dative-exporter-dialog-widget'
        title: 'Export'
        width: width
        height: height
        create: =>
          @fontAwesomateCloseIcon()
          @tooltipify()
        close: =>
          @closeAllTooltips()
        open: (event, ui) =>
          @moveToTop()

    # Select/highlight all of the export text.
    selectAllExportText: ->
      @utils.selectText @$('.dative-exporter-dialog-content pre')[0]

    tooltipify: ->
      @$('.dative-tooltip').tooltip()

    defaultPosition: ->
      my: "center"
      at: "center"
      of: @$target.first().parent().parent()

    guify: ->

    setToBeExported: (options) ->
      if options.model
        for exporterView in @exporterViews
          exporterView.setModel options.model
      if options.collection
        for exporterView in @exporterViews
          exporterView.setCollection options.collection

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

