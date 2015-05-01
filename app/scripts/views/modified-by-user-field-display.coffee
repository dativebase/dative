define [
  './field-display'
  './modified-by-user-representation-set'
], (FieldDisplayView, ModifiedByUserRepresentationSetView) ->

  # Modified By User Field Display View
  # -----------------------------------
  #
  # A view for displaying a FieldDB `modifiedByUser` array, i.e., an array of
  # objects with `username` `timestamp`, `gravatar`, and `appVersion`
  # attributes, e.g.,
  #
  #   appVersion: "2.38.16.07.59ss Fri Jan 16 08:02:30 EST 2015"
  #   gravatar: "5b7145b0f10f7c09be842e9e4e58826d"
  #   timestamp: 1423667274803
  #   username: "jdoe"
  #
  # NOTE: @cesine: I ignore the first modifier object because it is different
  # than the rest: it has no timestamp. I think it just redundantly records
  # the enterer. Am I right about that?

  class ModifiedByUserFieldDisplayView extends FieldDisplayView

    getRepresentationView: ->
      new ModifiedByUserRepresentationSetView @context

    getContext: ->
      _.extend(super,
        subattribute: 'username')

    # If the `modifiedByUser` is an array with 1 or fewer elements, we don't
    # display anything.
    shouldBeHidden: ->
      modifiersArray = @context.value or []
      if modifiersArray.length < 2 then true else false

