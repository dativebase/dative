define [
  './field'
  './comments-input-set'
], (FieldView, CommentsInputSetView) ->

  # Comments Field View
  # -----------------------
  #
  # A field view specifically for an array of comment objects, i.e.,
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
  # The HTML that this view governs consists of:
  #
  # - a label (built by the base class `FieldView`)
  # - an input collection (i.e., a set if input sets, one for each comment)
  #   governed by an instance of `CommentsInputView`.

  class CommentsFieldView extends FieldView

    getInputView: ->
      new CommentsInputSetView @context

