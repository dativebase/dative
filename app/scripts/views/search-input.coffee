define [
  './input'
  './filter-expression'
  './../utils/utils'
  './../templates/div-input'
], (InputView, FilterExpressionView, utils, divInputTemplate) ->

  # Search Input View
  # -----------------
  #
  # A view for a complex structure of buttons, selects and inputs that
  # represent a single search over forms. Most of the heavy lifting here is
  # done by the `FilterExpressionView` instance and its recursively
  # instantiated sub-instances.

  class SearchInputView extends InputView

    template: divInputTemplate

    initialize: (@context) ->
      @filterExpressionView = new FilterExpressionView
        model: @context.model
        filterExpression: @context.value.filter
        options: @context.options
        rootNode: true

    render: ->
      @$el.html @template(@context)
      @filterExpressionView.setElement @$(".#{@context.class}").first()
      @filterExpressionView.render()
      @listenToEvents()
      @rendered @filterExpressionView

    listenToEvents: ->
      super
      @listenTo @filterExpressionView, 'changed',
        @rootFilterExpressionViewChanged
      @listenTo @filterExpressionView, 'destroyMe',
        @filterExpressionWantsToBeDestroyed

    filterExpressionWantsToBeDestroyed: ->
      Backbone.trigger 'cantDeleteFilterExpressionOnlyChild'

    rootFilterExpressionViewChanged: ->
      @context.value.filter = @filterExpressionView.filterExpression
      @trigger 'setToModel'

    # When we trigger `setToModel`, our parent `SearchFieldView` will call this
    # method.
    getValueFromDOM: -> @context.value

