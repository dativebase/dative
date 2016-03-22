define [
  './html-snippet-representation'
  './related-model-representation'
  './form'
  './file'
  './collection'
  './../models/form'
  './../models/file'
  './../models/collection'
], (HTMLSnippetRepresentationView, RelatedModelRepresentationView, FormView,
  FileView, CollectionView, FormModel, FileModel, CollectionModel) ->


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

  class HTMLSnippetRepresentationViewCircular extends HTMLSnippetRepresentationView

    events:
      'click .link-to-resource': 'requestResourceFromServer'

    initialize: (@context) ->
      @resourceName2viewAndModel =
        form: [FormView, FormModel]
        file: [FileView, FileModel]
        collection: [CollectionView, CollectionModel]
      super

    postRender: ->
      @$('.link-to-resource.dative-tooltip').tooltip()
      @$('div.html-content-field-wrapper')
        .css("border-color", @constructor.jQueryUIColors().defBo)


