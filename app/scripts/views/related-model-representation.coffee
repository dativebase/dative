define [
  './base'
  './representation'
  './../models/base'
  './../templates/related-model-representation'
], (BaseView, RepresentationView, BaseModel,
  relatedModelRepresentationTemplate) ->

  # Related Model Representation View
  # ---------------------------------
  #
  # A view for the representation of a field such that the representation
  # consists of the field value which is a link that, when clicked, causes the
  # model represented to be displayed in a resource displayer dialog box.  #

  class RelatedModelRepresentationView extends RepresentationView

    # This two attributes should be overridden in subclasses.
    relatedModelClass: BaseModel
    relatedModelViewClass: BaseView

    template: relatedModelRepresentationTemplate

    valueFormatter: (value) ->
      value.name

    initialize: (@context) ->
      if @context.relatedModelClass
        @relatedModelClass = @context.relatedModelClass
      if @context.relatedModelViewClass
        @relatedModelViewClass = @context.relatedModelViewClass
      @context.hyphenatedAttribute = @utils.snake2hyphen @context.attribute
      @context.regularAttribute = @utils.snake2regular @context.attribute
      @events["click a.related-#{@context.hyphenatedAttribute}-display"] =
        'displayRelatedModel'

    events: {}

    render: ->
      super
      @listenToEvents()
      @guify()
      @

    listenToEvents: ->
      super
      if @relatedModel then @listenToRelatedModel()

    listenToRelatedModel: ->
      tmp = @utils.capitalize(
        @utils.snake2camel(@relatedModel.resourceNameCapitalized))
      event = "fetch#{tmp}Success"
      @listenTo @relatedModel, event, @fetchRelatedModelSuccess

    # Cause this related model to be displayed in a dialog box.
    displayRelatedModel: ->
      @relatedModel = new @relatedModelClass()
      @listenToRelatedModel()
      @relatedModel.fetchResource @getId()

    getId: ->
      @context.model.get(@context.attribute).id

    fetchRelatedModelSuccess: (relatedModelObject) ->
      @relatedModel.set relatedModelObject
      relatedModelView = new @relatedModelViewClass(model: @relatedModel)
      Backbone.trigger 'showResourceInDialog', relatedModelView, @$el

    guify: ->
      @$('.dative-tooltip').tooltip()

