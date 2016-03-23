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

      @referencedResourcesRequested = false
      @referencedFormsRequested = false
      @referencedFilesRequested = false

      @resourceName2viewAndModel =
        form: [FormView, FormModel]
        file: [FileView, FileModel]
        collection: [CollectionView, CollectionModel]
      @dummyFormModel = new FormModel()
      @dummyFileModel = new FileModel()

      @formModels = {}
      @formViews = []

      @fileModels = {}
      @fileViews = []

      @listenToEvents()

    template: homepageTemplate

    events:
      'click .link-to-resource': 'requestResourceFromServer'

    listenToEvents: ->
      super
      @listenTo @dummyFormModel, 'searchSuccess', @formSearchSuccess
      @listenTo @dummyFormModel, 'searchFail', @formSearchFail
      @listenTo @dummyFileModel, 'searchSuccess', @fileSearchSuccess
      @listenTo @dummyFileModel, 'searchFail', @fileSearchFail

    render: ->
      @listenToEvents()
      html = @resourceReferenceFormatter @html
      @$el.html @template(html: html, header: @header)
      @matchHeights()
      @fixRoundedBorders()
      @$('.link-to-resource.dative-tooltip').tooltip()
      @embedReferencedResources()
      @

    setHTML: (@html, @header) ->

    formSearchSuccess: (responseJSON) ->
      for formObject in responseJSON
        @formModels[formObject['id']] = new FormModel(formObject)
      @referencedFormsRequested = true
      @getReferencedResourcesRequested()
      @displayReferencedForms()

    formSearchFail: ->
      @referencedFormsRequested = true
      @getReferencedResourcesRequested()

    fileSearchSuccess: (responseJSON) ->
      for fileObject in responseJSON
        @fileModels[fileObject['id']] = new FileModel(fileObject)
      @referencedFilesRequested = true
      @getReferencedResourcesRequested()
      @displayReferencedFiles()

    fileSearchFail: ->
      @referencedFilesRequested = true
      @getReferencedResourcesRequested()

    # Display resource views for the forms and files that are referenced in
    # this home page.
    displayReferencedResources: ->
      @displayReferencedForms()
      @displayReferencedFiles()

    # Insert rendered form views into all the places in the home page where
    # there is an "embed me" form reference, e.g., "form[1]".
    displayReferencedForms: ->
      newFormViews = []
      @$('div.form-container').each((i, e) =>
        $e = @$ e
        formId = $e.data 'id'
        if formId of @formModels
          model = @formModels[formId]
          formView = new FormView model: model
          newFormViews.push formView
          $e.addClass 'dative-resource-widget dative-form-object
            dative-paginated-item dative-widget-center ui-corner-all'
          formView.setElement $e
          formView.render()
          @rendered formView
        else
          $e.html "There is no form with id #{formId}"
      )
      for formView in @formViews
        formView.close()
      @formViews = newFormViews

    displayReferencedFiles: ->
      newFileViews = []
      @$('div.file-container').each((i, e) =>
        $e = @$ e
        fileId = $e.data 'id'
        if fileId of @fileModels
          model = @fileModels[fileId]
          fileView = new FileView model: model
          newFileViews.push fileView
          $e.addClass 'dative-resource-widget dative-shadowed-widget ui-widget
            ui-widget-content ui-corner-all dative-paginated-item
            dative-widget-center'
          fileView.setElement $e
          fileView.render()
          @rendered fileView
        else
          $e.html "There is no file with id #{fileId}"
      )
      for fileView in @fileViews
        fileView.close()
      @fileViews = newFileViews

    # Embed views for any resources that are referenced in the home page.
    embedReferencedResources: ->
      if @referencedResourcesRequested
        @displayReferencedResources()
      else
        @requestReferencedResources()

    contentChanged: ->
      @referencedResourcesRequested = false
      @referencedFormsRequested = false
      @referencedFilesRequested = false

    requestReferencedResources: ->
      @requestReferencedForms()
      @requestReferencedFiles()

    getReferencedResourcesRequested: ->
      if @referencedFormsRequested and @referencedFilesRequested
        @referencedResourcesRequested = true
      else
        @referencedResourcesRequested = false

    requestReferencedForms: ->
      formIds = []
      @$('div.form-container').each (i, e) =>
        formIds.push @$(e).data('id')
      if formIds.length
        search =
          filter: ["Form", "id", "in", formIds]
          order_by: ["Form", "id", "desc" ]
        @dummyFormModel.search search, null, false # `false` means no pagination
      else
        @referencedFormsRequested = true
        @getReferencedResourcesRequested()

    requestReferencedFiles: ->
      fileIds = []
      @$('div.file-container').each (i, e) =>
        fileIds.push @$(e).data('id')
      if fileIds.length
        search =
          filter: ["File", "id", "in", fileIds]
          order_by: ["File", "id", "desc" ]
        @dummyFileModel.search search, null, false # `false` means no pagination
      else
        @referencedFilesRequested = true
        @getReferencedResourcesRequested()

