define [
  './representation'
], (RepresentationView) ->

  # Related Resource Representation View
  # ------------------------------------
  #
  # ...

  class RelatedResourceRepresentationView extends RepresentationView

    initialize: (@context) ->
      @contextualize()

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
        'resourceModelClass'
        'resourceViewClass'
        'resourceAsString'
      ]
        @[attr] = @context[attr]
      if 'getRelatedResourceId' of @context
        @getRelatedResourceId = -> @context.getRelatedResourceId.call @

    setContextValue: ->
      #console.log '@context.value ...'
      #console.log @context.value
      try
        if @context.value
          @context.value = "<a
            href='javascript:;'
            class='field-display-link
                  dative-tooltip'
            title='click here to view this #{@utils.camel2regular @resourceName}
                  in the page'
            >#{@resourceAsString @context.value}</a>"
        else
          @context.value = ''
      catch error
        @context.value = ''

    events:
      'click a.field-display-link': 'displayRelatedResource'

    listenToEvents: ->
      super
      if @resourceModel then @listenToModel()

    listenToModel: ->
      @listenTo @resourceModel, "fetch#{@utils.capitalize @resourceName}Success",
        @fetchResourceSuccess

    # Cause this resource to be displayed in a dialog box.
    # TODO: check for an id on the model (or similar) prior to this so that we
    # don't unnecessarily re-fetch the resource.
    displayRelatedResource: ->
      if @resourceView
        @requestDialogView()
      else
        @resourceModel = new @resourceModelClass()
        @listenToModel()
        id = @getRelatedResourceId()
        @resourceModel.fetchResource id

    getRelatedResourceId: ->
      @context.model.get("#{@attributeName}").id

    fetchResourceSuccess: (resourceObject) ->
      @resourceModel.set resourceObject
      if @resourceViewClass
        @resourceView = new @resourceViewClass(model: @resourceModel)
      else
        @resourceView = true
      @requestDialogView()

    # Sometimes circular dependencies arise if we try to import a particular
    # ResourceView sub-class. If `@resourceViewClass` is undefined, then we let
    # the event listener supply the appropriate view class for the model.
    requestDialogView: ->
      if @resourceViewClass
        Backbone.trigger 'showResourceInDialog', @resourceView, @$el
      else
        Backbone.trigger 'showResourceModelInDialog', @resourceModel,
          "#{@utils.capitalize @resourceName}View"

    guify: ->
      @$('.dative-tooltip').tooltip()

