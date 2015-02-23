define ['./textarea-button-input'], (TextareaButtonInputView) ->

  # Comment Input View
  # ------------------
  #
  # A view for a single (FieldDB) comment.
  #
  # Just a `TextareaButtonInputView` that also returns the username of the
  # currently logged-in user and the current timestamp when `getValueFromDOM`
  # is called:
  #
  #   {
  #     text: 'I like this form',
  #     username: 'john',
  #     timestamp: 123456789
  #   }

  class CommentInputView extends TextareaButtonInputView

    getValueFromDOM: ->
      defaultValue = super
      defaultValue[@context.usernameName] = @getLoggedInUsername()
      defaultValue[@context.timestampName] = @utils.getTimestamp()
      defaultValue

