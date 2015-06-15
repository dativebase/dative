define [
  './base'
  './field-display'
  './../models/base'
], (BaseView, FieldDisplayView, BaseModel) ->

  class RelatedModelDisplayView extends FieldDisplayView

    # This two attributes should be overridden in subclasses.
    relatedModelClass: BaseModel
    relatedModelViewClass: BaseView

    getContext: ->
      context = super
      try
        context.value = "<a
          href='javascript:;'
          class='field-display-link
            subcorpus-#{@utils.snake2hyphen @attribute}-display
            dative-tooltip'
          title='click here to view this #{@utils.snake2regular @attribute} in
            the page'
          >#{context.value.name}</a>"
      catch
        context.value = ''
      context

    initialize: (options) ->
      super options
      @events["click a.subcorpus-#{@utils.snake2hyphen @attribute}-display"] =
        'displayRelatedModel'

    events: {}

    listenToEvents: ->
      super
      if @relatedModel then @listenToRelatedModel()

    listenToRelatedModel: ->
      event =
        "fetch#{@utils.capitalize @utils.snake2camel(@relatedModel.resourceNameCapitalized)}Success"
      @listenTo @relatedModel, event, @fetchRelatedModelSuccess

    # Cause this related model to be displayed in a dialog box.
    displayRelatedModel: ->
      @relatedModel = new @relatedModelClass()
      @listenToRelatedModel()
      @relatedModel.fetchResource @context.model.get(@attribute).id

    fetchRelatedModelSuccess: (relatedModelObject) ->
      @relatedModel.set relatedModelObject
      relatedModelView = new @relatedModelViewClass(model: @relatedModel)
      Backbone.trigger 'showResourceInDialog', relatedModelView, @$el

    guify: ->
      @$('.dative-tooltip').tooltip()

