define [
  'backbone'
  './input-set'
], (Backbone, InputSetView) ->

  # Comments Input Set View
  # -----------------------
  #
  # A view for a *set* of input field sets for modifying an array of comment
  # objects. That is, something like:
  #
  #   comments = [
  #     {
  #       text: 'I like this form',
  #       username: 'john',
  #       timestamp: 123456789
  #     }, {
  #       text: 'I don’t',
  #       username: 'mary',
  #       timestamp: 123456799
  #     }
  #   ]
  #
  # TODO: user roles/permissions need to be reflected here. E.g., can you
  # delete/modify another user's comment?

  class CommentsInputSetView extends InputSetView

    # We simply tell the base class `InputSetView` that the (editable)
    # subattribute is named "text". The default logic of `InputSetView` does
    # the rest.
    initialize: (options) ->
      options.subattribute = 'text'
      super

