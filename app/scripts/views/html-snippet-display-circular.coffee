define [
  './html-snippet-display'
  './html-snippet-representation-circular'
], (HTMLSnippetFieldDisplayView, HTMLSnippetRepresentationViewCircular) ->

  # HTML Snippet Field Display View -- Circular
  # -------------------------------------------
  #
  # A view for displaying an HTML snippet, e.g., the HTML generated from the
  # `page_content` value of a user.

  class HTMLSnippetFieldDisplayViewCircular extends HTMLSnippetFieldDisplayView

    getRepresentationView: ->
      new HTMLSnippetRepresentationViewCircular @context

