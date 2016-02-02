define [
  './html-snippet-representation'
  './related-model-representation'
  './form'
  './file'
  './../models/form'
  './../models/file'
], (HTMLSnippetRepresentationView, RelatedModelRepresentationView, FormView,
  FileView, FormModel, FileModel) ->


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

    resourceName2viewAndModel:
      form: [FormView, FormModel]
      file: [FileView, FileModel]

    postRender: ->
      @$('.link-to-resource.dative-tooltip').tooltip()
      @$('div.html-content-field-wrapper')
        .css("border-color", @constructor.jQueryUIColors().defBo)

    requestResourceFromServer: (event) ->
      $target = $ event.currentTarget
      resourceName = $target.attr 'data-resource-name'
      resourceId = $target.attr 'data-resource-id'
      uniqueIdentifier = "#{resourceName}-#{resourceId}"
      anchorName = $target.text()
      [viewClass, modelClass] = @getLinkedToViewAndModel resourceName
      if viewClass
        model = new modelClass()
        view = new viewClass(model: model)
        view.displayResourceInDialog = (modelObject) ->
          view.model.set modelObject
          Backbone.trigger 'showResourceInDialog', @, @$el
        event = "fetch#{@utils.capitalize resourceName}Success"
        view.listenToOnce model, event, view.displayResourceInDialog
        model.fetchResource resourceId
      else
        console.log "Sorry, we don't have views and models for #{resourceName}
          resources yet."

    getLinkedToViewAndModel: (resourceName) ->
      if resourceName of @resourceName2viewAndModel
        @resourceName2viewAndModel[resourceName]
      else
        [null, null]


