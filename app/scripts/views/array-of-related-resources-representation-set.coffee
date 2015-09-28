define [
  './representation-set'
], (RepresentationSetView) ->

  # Array of Related Resources Representation Set View
  # --------------------------------------------------
  #
  # A sub-class of `RepresentationSetView` which displays each value in the set
  # not just as a string but as a link that, when clicked, causes the clicked
  # resource to be displayed in a dialog view.

  class ArrayOfRelatedResourcesRepresentationSetView extends RepresentationSetView

    initialize: (@context) ->
      @relatedResourceRepresentationViewClass =
        @context.relatedResourceRepresentationViewClass
      super

    # Override this in sub-classes in order to change the type of sub-representation.
    getRepresentationView: (representationContext) ->
      new @relatedResourceRepresentationViewClass representationContext

    # Call `refresh` on all representation sub-views, giving them a new
    # `context`.
    refreshRepresentationViews: ->
      tmp = _.zip(@representationViews, @context.value)
      for [representationView, object] in tmp
        representationView.refresh @getRepresentationContext(object)

