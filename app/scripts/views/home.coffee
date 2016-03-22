define [
  'backbone'
  './base'
  './form'
  './file'
  './collection'
  './../models/form'
  './../models/file'
  './../models/collection'
  './../templates/home'
], (Backbone, BaseView, FormView, FileView, CollectionView, FormModel,
  FileModel, CollectionModel, homepageTemplate) ->

  # Home Page View
  # --------------

  class HomePageView extends BaseView

    initialize: (options) ->
      @html = null
      @header = null
      @embeddedResourcesRequested = false
      @resourceName2viewAndModel =
        form: [FormView, FormModel]
        file: [FileView, FileModel]
        collection: [CollectionView, CollectionModel]

    events:
      'click .link-to-resource': 'requestResourceFromServer'
      'mouseenter .homepage': 'requestEmbeddedResources'

    # TODO: request any resources that are referenced in the home page from the
    # server so that we can display them appropriately.
    requestEmbeddedResources: ->
      if not @embeddedResourcesRequested
        @embeddedResourcesRequested = true
        formIds = []
        @$('div.form-container').each (i, e) =>
          formIds.push @$(e).data('id')
        console.log formIds
        fileIds = []
        @$('div.file-container').each (i, e) =>
          fileIds.push @$(e).data('id')
        console.log fileIds
        console.log 'REQUEST'

    template: homepageTemplate

    setHTML: (@html, @header) ->

    render: ->
      html = @resourceReferenceFormatter @html
      @$el.html @template(html: html, header: @header)
      @matchHeights()
      @fixRoundedBorders()
      @$('.link-to-resource.dative-tooltip').tooltip()
      @

