define [
  'backbone'
  './input-set'
  './comment-input'
], (Backbone, InputSetView, CommentInputView) ->

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
  # TODO: user roles/permissions need to be reflected here. E.g., should you
  # be able to delete/modify another user's comment?

  class CommentsInputSetView extends InputSetView

    # We simply tell the base class `InputSetView` that the (editable)
    # subattribute is named "text". The default logic of `InputSetView` does
    # the rest.
    initialize: (options) ->
      options.subattribute = 'text'
      super

    # The `CommentInputView` is just the default (`TextareaButtonInputView`)
    # input view except that it adds the username of the currently logged in
    # user and the current timestamp to the returned object value.
    getInputView: (inputContext) ->
      new CommentInputView inputContext

    # The object returned by this method is passed to each input view on
    # initialization. We create attributes names for the username and timestamp
    # attributes of each input; e.g., "comments-0.username".
    getInputContext: (index, object) ->
      defaultInputContext = super
      defaultInputContext.usernameName = @getArrayItemAttributeName(
        @attribute, index, 'username')
      defaultInputContext.timestampName = @getArrayItemAttributeName(
        @attribute, index, 'timestamp')
      defaultInputContext

