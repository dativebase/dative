define [
  './representation-set'
  './modified-by-user-representation'
], (RepresentationSetView, ModifiedByUserRepresentationView) ->

  # Modified By User Representation Set View
  # ----------------------------------------
  #
  # A view for a *set* of modifiedByUser representations.

  class ModifiedByUserRepresentationSetView extends RepresentationSetView

    # Override `RepresentationSetView`'s default with a
    # modified-by-user-appropriate representation view.
    getRepresentationView: (representationContext) ->
      new ModifiedByUserRepresentationView representationContext

    # Override `RepresentationSetView`'s default with
    # modified-by-user-appropriate context attributes.
    getRepresentationContext: (object) ->
      _.extend(super,
        usernameClass: @getClass 'username'
        usernameValue: object.username
        timestampClass: @getClass 'timestamp'
        timestampValue: new Date(object.timestamp)
        humanDatetime: @utils.humanDatetime
        timeSince: @utils.timeSince
      )

    render: ->
      # for representationView in @representationViews.reverse()[...-1]
      for representationView in @representationViews.reverse()
        @renderRepresentationView representationView
      @listenToEvents()

