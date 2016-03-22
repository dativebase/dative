define [
  './representation'
  './../templates/html-snippet-representation'
], (RepresentationView, HTMLSnippetRepresentationTemplate) ->

  # FormView, FormModel) ->


  # HTML Snippet Representation View
  # --------------------------------
  #
  # A view for the representation of an HTML snippet, e.g., the HTML generated
  # from the `page_content` value of a user.
  #
  # What's special about this is that OLD-specific references in the text need
  # to be interpreted and transformed into links or embedded images:
  #
  # - `form(<id>)(<text>)` is transformed into a link with text `<text>` that
  #    brings up the form with `id=<id>` in a dialog.
  # - `file(<id>)(<text>)` is the same as the above, but with files.
  # - `file[<id>]` embeds the content of the file with `id=<id>` in the HTML.

  class HTMLSnippetRepresentationView extends RepresentationView

    events:
      'click .link-to-resource': 'signalInabilityToLink'

    # In the "circular" subclass, this maps the name of a resource, e.g.,
    # 'form', to a tuple containing both a view and a model class for that
    # resource.
    resourceName2viewAndModel: {}

    postRender: ->
      @$('div.html-content-field-wrapper')
        .css("border-color", @constructor.jQueryUIColors().defBo)

    template: HTMLSnippetRepresentationTemplate

    valueFormatter: (value) ->
      @resourceReferenceFormatter value

    signalInabilityToLink: ->
      console.log 'Non-circular HTML snippet representation does not embed
        resources. Use `HTMLSnippetRepresentationViewCircular` instead.'

