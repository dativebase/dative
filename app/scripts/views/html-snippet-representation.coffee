define [
  './representation'
  './../templates/html-snippet-representation'
  './related-model-representation'
  './form'
  './../models/form'
], (RepresentationView, HTMLSnippetRepresentationTemplate,
  RelatedModelRepresentationView, FormView, FormModel) ->


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
      'click .link-to-resource': 'requestResourceFromServer'

    resourceName2viewAndModel:
      form: [FormView, FormModel]

    postRender: ->
      @$('.link-to-resource.dative-tooltip').tooltip()

    template: HTMLSnippetRepresentationTemplate

    valueFormatter: (value) ->
      value
        .replace(/(form|file)\((\d+)\)\(([^\(]+)\)/g,
          ($0, resourceName, resourceId, anchorName) ->
            "<a href='javascript:;'
              title='click here to view this #{resourceName} in the page'
              class='link-to-resource dative-tooltip'
              data-resource-name='#{resourceName}'
              data-resource-id='#{resourceId}'
              >#{anchorName}</a>"
        )
        .replace(/file\[(\d+)\]/g,
          ($0, fileId) ->
            console.log "you want to embed the file #{fileId}"
            "<div class='file-#{fileId}'>File #{fileId} will be embedded
              here</div>"
        )

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

