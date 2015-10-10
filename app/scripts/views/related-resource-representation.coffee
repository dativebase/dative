define [
  './representation'
  './../templates/related-resource-representation'
], (RepresentationView, relatedResourceRepresentationTemplate) ->

  # Related Resource Representation View
  # ------------------------------------
  #
  # This view is for the link that represents a related resource. Clicking this
  # link should cause the related resource to be displayed in a dialog box.

  class RelatedResourceRepresentationView extends RepresentationView

    template: relatedResourceRepresentationTemplate

    initialize: (@context) ->
      @contextualize()
      @listenToEvents()

    refresh: (@context) ->
      @contextualize()

    contextualize: ->
      @getAttributesFromContext()
      @setContextValue()

    getAttributesFromContext: ->
      for attr in [
        'subattribute'
        'resourceName'
        'attributeName'
        'resourcesCollectionClass'
        'resourceModelClass'
        'resourceViewClass'
        'resourceAsString'
      ]
        @[attr] = @context[attr]
      if 'getRelatedResourceId' of @context
        @getRelatedResourceId = -> @context.getRelatedResourceId.call @

    getEmptyValue: -> ''

    setContextValue: ->
      @context.resourceNameHuman = @utils.camel2regular @context.resourceName
      @context.emptyValue = @getEmptyValue()
      try
        if @context.value
          @context.value = @resourceAsString @context.value
        else
          @context.value = ''
      catch error
        @context.value = ''

    events:
      'click a.field-display-link': 'displayRelatedResource'

    listenToEvents: ->
      super
      @listenTo @model, "change:#{@attributeName}", @valueChanged
      # if @resourceModel then @listenToModel()

    listenToModel: ->
      @listenToOnce @resourceModel,
        "fetch#{@utils.capitalize @resourceName}Success",
        @fetchResourceSuccess

    valueChanged: -> @resourceView = null

    # Cause this resource to be displayed in a dialog box.
    # TODO: check for an id on the model (or similar) prior to this so that we
    # don't unnecessarily re-fetch the resource.
    displayRelatedResource: ->
      if @resourceView
        @requestDialogView()
      else
        @resourcesCollection = new @resourcesCollectionClass()
        @resourceModel =
          new @resourceModelClass({}, {collection: @resourcesCollection})
        @listenToModel()
        id = @getRelatedResourceId()
        @resourceModel.fetchResource id

    getRelatedResourceId: ->
      @context.model.get("#{@attributeName}").id

    fetchResourceSuccess: (resourceObject) ->
      @resourceModel.set resourceObject
      if @resourceViewClass
        searchPatternsObject =
          @context.searchPatternsObject?[@attributeName] or null
        @resourceView = new @resourceViewClass
          model: @resourceModel
          searchPatternsObject: searchPatternsObject
      else
        @resourceView = true
      @requestDialogView()

    # Sometimes circular dependencies arise if we try to import a particular
    # ResourceView sub-class. If `@resourceViewClass` is undefined, then we let
    # the event listener supply the appropriate view class for the model.
    requestDialogView: ->
      if @resourceViewClass
        Backbone.trigger 'showResourceInDialog', @resourceView, @$el
        @resourceView = null
      else
        Backbone.trigger 'showResourceModelInDialog', @resourceModel,
          @resourceName

    guify: ->
      @$('.dative-tooltip').tooltip()

