define [
  './representation-set'
  './comment-representation'
], (RepresentationSetView, CommentRepresentationView) ->

  # Comments Representation Set View
  # --------------------------------
  #
  # A view for a *set* of comment representations.

  class CommentsRepresentationSetView extends RepresentationSetView

    # Override `RepresentationSetView`'s default with a comment-appropriate
    # representation view.
    getRepresentationView: (representationContext) ->
      new CommentRepresentationView representationContext

    # Override `RepresentationSetView`'s default with comment-appropriate
    # context attributes.
    getRepresentationContext: (object) ->
      _.extend(super,
        textClass: @getClass 'text'
        textValue: object.text
        usernameClass: @getClass 'username'
        usernameValue: object.username
        timestampClass: @getClass 'timestamp'
        timestampValue: new Date(object.timestamp)
        humanDatetime: @utils.humanDatetime
        timeSince: @utils.timeSince
      )

    render: ->
      for representationView in @representationViews.reverse()
        if representationView.context.textValue
          @renderRepresentationView representationView
      @listenToEvents()

