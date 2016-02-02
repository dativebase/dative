define [
  './base'
  './../templates/exporter'
], (BaseView, exporterTemplate) ->

  # Base calss for creating exporter views. An exporter view exports
  # a single resource or a collections thereof. It defines an interface for
  # selecting (and perhaps customizing) the export as well as the logic for
  # querying the server (if necessary) and formatting the data for export.

  class ExporterView extends BaseView

    # The user has clicked on the "export" button so we should initiate the
    # request for the data, or just present the in-memory data to them in a
    # certain format. What happens here will depend on the purpose of the
    # particular exporter.
    export: (event) ->

    # Return the title of the exporter, something like 'JSON' or 'CSV'
    title: -> 'Title'

    # Return a longer description of this exporter.
    # TODO: auto-truncate this with a "more" link that reveals the rest of the
    # text.
    description: -> 'A description of this exporter'

    # Return an array that determines whether this exporter can export a single
    # resource model, a collection of models, or both. It should contain
    # 'collection', 'model', or '*' to indicate the respective option.
    exportTypes: -> ['collection']

    # Return an array that specifies the names (uncapitalized, camelCase) of the
    # resources that the exporter exports. Return `['*']` for an exporter that
    # exports all resources.
    exportResources: -> ['*']

    # Return `true` if this exporter has a "settings" button that reveals
    # settings controls to further configure the export.
    # NOTE: exporter settings have not yet been implemented.
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
      @$('.exporter-export-content-pre-container')
        .css 'border-color': @constructor.jQueryUIColors().defBo

    listenToEvents: ->
      super

    events:
      'click .export': 'export'
      'click .exporter-settings-button': 'toggleSettingsInterface'
      'click .select-all': 'selectAllExportText'

    # Select/highlight all of the export text, if applicable.
    selectAllExportText: ->
      @utils.selectText @$('.exporter-export-content pre')[0]

    # Make the input `model` the "target" of this exporter, i.e., the thing to
    # be exported. Update the interface based on this fact.
    setModel: (@model) ->
      @collection = null
      @resetInterface()
      if 'model' in @exportTypes() or '*' in @exportTypes()
        if '*' in @exportResources() or
        @model.resourceName in @exportResources()
          @$el.show()
        else
          @$el.hide()
      else
        @$el.hide()

    # Make the input `collection` the "target" of this exporter, i.e., the
    # thing to be exported. Update the interface based on this fact.
    setCollection: (@collection) ->
      @model = null
      @resetInterface()
      if 'collection' in @exportTypes() or '*' in @exportTypes()
        if '*' in @exportResources() or
        @collection.resourceName in @exportResources()
          @$el.show()
        else
          @$el.hide()
      else
        @$el.hide()

    resetInterface: ->
      @clearExportContent()
      @updateDescription()
      @updateControls()
      @hideExportContent()

    hideExportContent: ->
      @$(@contentContainerSelector()).hide()

    updateDescription: ->
      description = @description()
      @$('.exporter-description').html description

    updateControls: ->

    clearControls: ->
      @$('.exporter-export-controls').html ''

    # Add a "Select All" button to the exporter's controls <div>.
    selectAllButton: ->
      if @$('button.select-all').length == 0
        button = "<button class='select-all dative-tooltip'
          title='Select all of the text of this export'
          >Select all</button>"
        @$('.exporter-export-controls').append button
        @$('.exporter-export-controls button.select-all').button()
        @$('.exporter-export-controls .dative-tooltip').tooltip()

    clearExportContent: ->
      @$('.exporter-export-content').html ''

    # Our own method for fetching the data in a collection. We implement this
    # here because sometimes we don't want the default `ResourcesCollection`
    # behaviour of JSON-parsing the result since sometimes we want to return
    # the result exactly as it is returned by the server, with no client-side
    # post-processing to slow things down.
    fetchResourceCollection: (parseJSON=false) ->
      # add pagination params here, if needed; though note that these will
      # change the returned output from a JSON array to a JSON object ...
      options = {}
      @fetchResourceCollectionStart()
      @collection.model.cors.request(
        parseJSON: parseJSON
        method: @collection.getResourcesHTTPMethod()
        url: @collection.getResourcesPaginationURL options
        payload: @collection.getResourcesPayload options
        onload: (response, xhr) =>
          @fetchResourceCollectionEnd()
          if xhr.status is 200
            @fetchResourceCollectionSuccess response
          else
            @fetchResourceCollectionFail()
        onerror: (responseJSON) =>
          @fetchResourceCollectionEnd()
          @fetchResourceCollectionFail()
      )

    fetchResourceCollectionEnd: ->
      @enableExportButton()

    fetchResourceCollectionStart: ->
      @disableExportButton()

    fetchResourceCollectionFail: ->
      console.log 'fetch resource collection fail'
      @$('.exporter-export-content')
        .html 'Sorry, an error occurred when generating your export.'

    # Do something here with the JSON string returned by the server, e.g.,
    # present it to the user as an anchor that triggers a file download.
    fetchResourceCollectionSuccess: (response) ->

    removeSelectAllButton: ->
      @$('.select-all').remove()

    toggleSettingsInterface: ->
      $target = @$ '.exporter-settings'
      if $target.is ':visible'
        $target.slideUp()
      else
        $target.slideDown().html 'hey there'

    disableExportButton: ->
      @$('button.export').button 'disable'

    enableExportButton: ->
      @$('button.export').button 'enable'

