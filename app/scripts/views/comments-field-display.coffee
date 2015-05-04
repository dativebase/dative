define [
  './field-display'
  './comments-representation-set'
], (FieldDisplayView, CommentsRepresentationSetView) ->

  # Comments Field Display View
  # ---------------------------
  #
  # A view for displaying an array of comment objects. This is for displaying
  # a FieldDB comments array, i.e., an array of objects with `text`,
  # `username`, and `timestamp` attributes.

  class CommentsFieldDisplayView extends FieldDisplayView

    getContext: ->
      _.extend(super,
        subattribute: 'text')

    getRepresentationView: ->
      new CommentsRepresentationSetView @context

