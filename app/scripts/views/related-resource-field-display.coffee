define [
  './resource'
  './field-display'
  './../models/resource'
], (ResourceView, FieldDisplayView, ResourceModel) ->

  # Related Resource Field Display View
  # -----------------------------------
  #
  # This is a field display that displays a related resource as a descriptive
  # link that, when clicked retrieves the resource data from the server and
  # causes it to be displayed in a dialog box.

  class RelatedResourceFieldDisplayView extends FieldDisplayView

    # Override these in sub-classes.
    resourceName: 'resource'
    attributeName: 'resource'
    resourceModelClass: ResourceModel
    resourceViewClass: ResourceView
    # This method should return a string representation of the related resource.
    resourceAsString: (resource) -> resource.name

    getContext: ->
      context = super
      try
        if context.value
          context.value = "<a
            href='javascript:;'
            class='field-display-link
                  dative-tooltip'
            title='click here to view this #{@utils.camel2regular @resourceName}
                  in the page'
            >#{@resourceAsString context.value}</a>"
        else
          context.value = ''
      catch
        context.value = ''
      context

    events:
      'click a.field-display-link': 'displayRelatedResource'

    listenToEvents: ->
      super
      if @model then @listenToModel()

    listenToModel: ->
      @listenTo @model, "fetch#{@utils.capitalize @resourceName}Success",
        @fetchResourceSuccess

    # Cause this resource to be displayed in a dialog box.
    # TODO: check for an id on the model (or similar) prior to this so that we
    # don't unnecessarily re-fetch the resource.
    displayRelatedResource: ->
      if @resourceView
        @requestDialogView()
      else
        @model = new @resourceModelClass()
        @listenToModel()
        id = @context.model.get("#{@attributeName}").id
        @model.fetchResource id

    fetchResourceSuccess: (resourceObject) ->
      @model.set resourceObject
      @resourceView = new @resourceViewClass(model: @model)
      @requestDialogView()

    requestDialogView: ->
      Backbone.trigger 'showResourceInDialog', @resourceView, @$el

    guify: ->
      @$('.dative-tooltip').tooltip()

    # Return an in-line CSS style to hide the HTML of an empty form attribute
    # Note the use of `=>` so that the ECO template knows to use this view's
    # context.
    shouldBeHidden: ->
      value = @context.value
      if _.isDate(value) or _.isNumber(value) or _.isBoolean(value)
        false
      else if _.isEmpty(value) or @isValueless(value)
        true
      else
        false

