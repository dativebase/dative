define [
  './field'
  './value-representation'
], (FieldView, ValueRepresentationView) ->

  # Representation Set View
  # -----------------------
  #
  # A view for a *set* of field representations. This is used for displaying
  # form attributes that are valuated as arrays, e.g., OLD translations or
  # FieldDB comments.
  #
  # The value of `@context.value` (where @context is the object passed to the
  # constructor) is expected to be an array. Each object in the value array is
  # assigned its own representation view.

  class RepresentationSetView extends FieldView

    initialize: (@context) ->
      @attribute = @context.attribute
      @subattribute = @context.subattribute
      @activeServerType = @getActiveServerType()
      @representationViews = []
      @getRepresentationViews()

    # Inheriting from `FieldView` is good for re-using some methods, but we
    # don't want to doubly listen to events that `FieldView`-inheriting
    # super-view is already listening to.
    events: {}

    # Add representation views to `@representationViews`, one for each object in `@context.value`.
    getRepresentationViews: ->
      for object in @context.value
        @pushRepresentationView object

    # Override this in sub-classes in order to change the type of sub-representation.
    getRepresentationView: (representationContext) ->
      new ValueRepresentationView representationContext

    # Create a view instance for a representation object, add it to
    # `@representationViews`, and return the view instance.
    pushRepresentationView: (object) ->
      representationContext = @getRepresentationContext object
      representationView = @getRepresentationView representationContext
      @representationViews.push representationView
      representationView

    # The object returned by this method is passed to each representation view on
    # initialization.
    getRepresentationContext: (object) ->
      tmp =
        attribute:         @attribute
        subattribute:      @subattribute
        class: @getClass @subattribute
        title: @getTooltip "#{@attribute}.#{@subattribute}"
        value: object[@subattribute]
      _.extend {}, @context, tmp

    render: ->
      for representationView in @representationViews
        @renderRepresentationView representationView
      @listenToEvents()

    # Render an representation set view; setting `animate` to true will cause `slideDown`.
    renderRepresentationView: (representationView) ->
      @$el.append representationView.render().el
      @rendered representationView

