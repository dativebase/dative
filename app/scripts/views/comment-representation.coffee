define [
  './representation'
  './../templates/comment-representation'
], (RepresentationView, commentRepresentationTemplate) ->

  # Comment Representation View
  # ---------------------------
  #
  # A view for the representation of a single FieldDB comment (i.e., an object
  # with three relevant attributes: `text`, `username`, and `timestamp`).

  class CommentRepresentationView extends RepresentationView

    template: commentRepresentationTemplate

