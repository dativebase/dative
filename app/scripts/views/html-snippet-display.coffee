define [
  './field-display'
  './html-snippet-representation'
], (FieldDisplayView, HTMLSnippetRepresentationView) ->

  # HTML Snippet Field Display View
  # -------------------------------
  #
  # A view for displaying an HTML snippet, e.g., the HTML generated from the
  # `page_content` value of a user.

  class HTMLSnippetFieldDisplayView extends FieldDisplayView

    fieldDisplayLabelContainerClass: 'dative-field-display-label-container top'
    fieldDisplayRepresentationContainerClass:
      'dative-field-display-representation-container full-width html-snippet'

    getRepresentationView: ->
      new HTMLSnippetRepresentationView @context

    guify: ->
      super
      @$('.dative-field-display-representation-container.html-snippet')
        .css 'border-color': @constructor.jQueryUIColors().defBo


