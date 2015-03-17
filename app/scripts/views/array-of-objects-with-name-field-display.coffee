define [
  './field-display'
  './representation-set'
], (FieldDisplayView, RepresentationSetView) ->

  # Array of Objects with Name Field Display View
  # ----------------------------------------------
  #
  # A view for displaying an array of objects that have `title` attributes.

  class ArrayOfObjectsWithNameFieldDisplayView extends FieldDisplayView

    getContext: ->
      _.extend(super,
        subattribute: 'name')

    getRepresentationView: ->
      new RepresentationSetView @context

