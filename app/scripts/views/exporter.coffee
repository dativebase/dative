define [
  './base'
  './../templates/exporter'
], (BaseView, exporterTemplate) ->

  # Base calss for creating exporter views. An exporter view exports
  # a single resource or a collections thereof. It defines an interface for
  # selecting (and perhaps customizing) the export as well as the logic for
  # querying the server and formatting the data for export.

  class ExporterView extends BaseView

    # Change `title` and `description` in sub-classes

    title: ->
      'Title'

    description: ->
      'A description of this exporter'

    # This array should contain 'collection' or 'model' or '*'
    exportTypes: ->
      ['collection']

    # This array should contain the names (uncapitalized, camelCase) of the
    # resources that the exporter exports. Set to `['*']` for an exporter that
    # exports all resources.
    exportResources: ->
      ['*']

    contentSelector: -> '.exporter-export-content'
    contentContainerSelector: -> '.exporter-export-content-container'

    template: exporterTemplate
    tagName: 'div'
    className: 'exporter-container'

    initialize: (options) ->
      @model = null
      @collection = null
      @listenToEvents()

    render: ->
      @listenToEvents()
      @html()
      @guify()
      @

    html: ->
      context =
        title: @title()
        description: @description()
      @$el.html @template(context)

    guify: ->
      @$('button').button()
      @$('.dative-tooltip').tooltip
        position: @tooltipPositionRight('+100')
      @$(@contentContainerSelector()).hide()

    listenToEvents: ->
      super

    events:
      'click .export': 'export'
      'click .select-all': 'selectAllExportText'

    # Select/highlight all of the export text.
    selectAllExportText: ->
      @utils.selectText @$('.exporter-export-content pre')[0]

    setModel: (@model) ->
      console.log 'in setModel with this resource ...'
      console.log @model.resourceName
      @collection = null
      if 'model' in @exportTypes() or '*' in @exportTypes()
        if '*' in @exportResources() or
        @model.resourceName in @exportResources()
          @$el.show()
        else
          @$el.hide()
      else
        @$el.hide()

    setCollection: (@collection) ->
      console.log 'in setCollection with this resource ...'
      console.log @collection.resourceName
      @model = null
      if 'collection' in @exportTypes() or '*' in @exportTypes()
        if '*' in @exportResources() or
        @collection.resourceName in @exportResources()
          @$el.show()
        else
          @$el.hide()
      else
        @$el.hide()

    # The user has clicked on the "export" button so we should initiate the
    # request for the data.
    export: (event) ->

    spinnerOptions: ->
      options = super
      options.top = '50%'
      options.left = '-10%'
      options

    spin: -> @$('.selector').first().spin @spinnerOptions()

    stopSpin: -> @$('.selector').first().spin false


