define [
  './base'
  './resource'
  './../utils/globals'
  './../utils/tooltips'
  './../templates/resource-as-row'
], (BaseView, ResourceView, globals, tooltips, resourceAsRowTemplate) ->

  # Resource-as-Row View
  # --------------------
  #
  # For displaying individual resources as rows; i.e., essentially treating the
  # resource as an array of string values that could be displayed in a
  # 2-dimensional matrix, i.e., a table.

  class ResourceAsRowView extends BaseView

    # Override these in sub-classes.
    resourceName: 'resource'

    # This is the regular resource view class; it is used when the "view"
    # button is clicked.
    resourceViewClass: ResourceView

    # Override this in sub-classes in order to control the left-to-right order
    # of attributes in the view display, and which attributes are displayed.
    orderedAttributes: []

    template: resourceAsRowTemplate
    tagName: 'div'
    #className: 'resource-as-row-row dative-shadowed-widget ui-corner-all'
    className: 'resource-as-row-row'

    # Since this will be called from within templates, the `=>` is necessary.
    resourceNameHumanReadable: =>
      @utils.camel2regular @resourceName

    initialize: (options) ->
      @isHeaderRow = options.isHeaderRow or false
      @resourceNameCapitalized = @utils.capitalize @resourceName
      @resourceNamePlural = @utils.pluralize @resourceName
      @resourceNamePluralCapitalized = @utils.capitalize @resourceNamePlural
      @activeServerType = @getActiveServerType()
      @addUpdateType = @getUpdateViewType()

    getUpdateViewType: -> if @model.get('id') then 'update' else 'add'

    render: ->
      @html()
      @guify()
      @listenToEvents()
      @

    html: ->
      @$el.html @template(@getContext())

    getContext: ->
      model: @getModelAsScalar()
      activeServerType: @activeServerType
      addUpdateType: @addUpdateType
      resourceName: @resourceName
      resourceNameHumanReadable: @resourceNameHumanReadable
      isHeaderRow: @isHeaderRow

    events:
      'click .select': 'selectResource'
      'click .view': 'viewResource'

    selectResource: (event) ->
      @stopEvent event
      @trigger 'selectMe', @

    viewResource: (event) ->
      @stopEvent event
      Backbone.trigger 'showResourceModelInDialog', @model, 'FileView'

    guify: ->
      @$('button').button()
      @$('.dative-tooltip').tooltip()

    # Return an object representing the model such that all attribute values
    # are scalars, i.e., strings or numbers.
    getModelAsScalar: ->
      output = {}
      if @orderedAttributes.length
        iterator = @orderedAttributes
      else
        iterator = _.keys @model.attributes
      for attribute in iterator
        value = @model.attributes[attribute]
        output[attribute] = @scalarTransform attribute, value
      output

    # Override this in sub-classes with something better/resource-specific.
    # (Note: this method assumes a File model currently.)
    scalarTransform: (attribute, value) ->
      if @isHeaderRow
        value
      else if value
        if attribute in ['elicitor', 'enterer', 'modifier', 'verifier', 'speaker']
          "#{value.first_name} #{value.last_name}"
        else if attribute is 'size'
          @utils.humanFileSize value, true
        else if @utils.type(value) in ['string', 'number']
          value
        else
          JSON.stringify value
      else
        JSON.stringify value

