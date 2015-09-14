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

    hasSettings: -> false

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
        hasSettings: @hasSettings()
      @$el.html @template(context)

    guify: ->
      @$('button').button()
      @$('.dative-tooltip').tooltip
        position: @tooltipPositionRight('+100')
      @$(@contentContainerSelector()).hide()
      @$('.exporter-settings').hide()

    listenToEvents: ->
      super

    events:
      'click .export': 'export'
      'click .exporter-settings-button': 'toggleSettingsInterface'
      'click .select-all': 'selectAllExportText'

    # Select/highlight all of the export text.
    selectAllExportText: ->
      @utils.selectText @$('.exporter-export-content pre')[0]

    setModel: (@model) ->
      @collection = null
      @clearExportConent()
      @updateDescription()
      @updateControls()
      if 'model' in @exportTypes() or '*' in @exportTypes()
        if '*' in @exportResources() or
        @model.resourceName in @exportResources()
          @$el.show()
        else
          @$el.hide()
      else
        @$el.hide()

    setCollection: (@collection) ->
      @model = null
      @clearExportConent()
      @updateDescription()
      @updateControls()
      if 'collection' in @exportTypes() or '*' in @exportTypes()
        if '*' in @exportResources() or
        @collection.resourceName in @exportResources()
          @$el.show()
        else
          @$el.hide()
      else
        @$el.hide()

    updateDescription: ->
      description = @description()
      @$('.exporter-description').text description

    updateControls: ->

    clearExportConent: ->
      @$('.exporter-export-content').html ''

    # The user has clicked on the "export" button so we should initiate the
    # request for the data.
    export: (event) ->

    spinnerOptions: ->
      options = super
      options.top = '0%'
      options.left = '0%'
      options.zIndex = '200'
      options.modal = true
      options

    fetchResourceCollection: ->
      options = {} # add pagination params here, if needed
      @fetchResourceCollectionStart()
      @collection.model.cors.request(
        parseJSON: false # No point in parsing JSON to JS if we just want JSON in the end anyways!
        method: @collection.getResourcesHTTPMethod()
        url: @collection.getResourcesPaginationURL options
        payload: @collection.getResourcesPayload options
        onload: (responseJSONString, xhr) =>
          @fetchResourceCollectionEnd()
          if xhr.status is 200
            @fetchResourceCollectionSuccess responseJSONString
          else
            @fetchResourceCollectionFail()
        onerror: (responseJSON) =>
          @fetchResourceCollectionEnd()
          @fetchResourceCollectionFail()
      )

    fetchResourceCollectionEnd: ->

    fetchResourceCollectionStart: ->

    fetchResourceCollectionFail: ->
      console.log 'fetch resource collection fail'
      @$('.exporter-export-content')
        .html 'Sorry, an error occurred when generating your export.'

    fetchResourceCollectionSuccess: (collectionJSONString) ->

    selectAllButton: ->
      button = "<button class='select-all dative-tooltip'
        title='Select all of the text of this export'
        >Select all</button>"
      @$('.exporter-export-controls').append button
      @$('.exporter-export-controls button.select-all').button()
      @$('.exporter-export-controls .dative-tooltip').tooltip()

    removeSelectAllButton: ->
      @$('.select-all').remove()

    toggleSettingsInterface: ->
      $target = @$ '.exporter-settings'
      if $target.is ':visible'
        $target.slideUp()
      else
        $target.slideDown().html 'hey there'

