define [
  './field-display'
  './representation-set'
], (FieldDisplayView, RepresentationSetView) ->

  # Array of Objects with Title Field Display View
  # ----------------------------------------------
  #
  # A view for displaying an array of objects that have `title` attributes.

  class ArrayOfObjectsWithTitleFieldDisplayView extends FieldDisplayView

    getContext: ->
      _.extend(super,
        subattribute: 'title')

    getRepresentationView: ->
      new RepresentationSetView @context

