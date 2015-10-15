define [
  './resource'
  './form'
  './file'
  './collection-controls'
  './collection-add-widget'
  './date-field-display'
  './related-user-field-display'
  './speaker-field-display'
  './enterer-field-display'
  './modifier-field-display'
  './source-field-display'
  './html-snippet-display-circular'
  './person-field-display'
  './array-of-objects-with-name-field-display'
  './array-of-related-tags-field-display'
  './array-of-related-files-field-display'
  './../models/form'
  './../models/file'
  './../collections/forms'
  './../collections/files'
], (ResourceView, FormView, FileView, CollectionControlsView,
  CollectionAddWidgetView, DateFieldDisplayView, RelatedUserFieldDisplayView,
  SpeakerFieldDisplayView, EntererFieldDisplayView, ModifierFieldDisplayView,
  SourceFieldDisplayView, HTMLSnippetFieldDisplayCircularView, PersonFieldDisplayView,
  ArrayOfObjectsWithNameFieldDisplayView, ArrayOfRelatedTagsFieldDisplayView,
  ArrayOfRelatedFilesFieldDisplayView, FormModel, FileModel, FormsCollection,
  FilesCollection) ->

  class ElicitorFieldDisplayView extends RelatedUserFieldDisplayView

    attributeName: 'elicitor'


  # We don't want our embedded `FormView` instances to have "duplicate" buttons
  # since they don't work (yet) when the form views are not sub-views of a
  # `FormsView` instance.
  class FormViewNoDuplicateAction extends FormView

    excludedActions: ['controls', 'data', 'duplicate']



  class MyHTMLSnippetFieldDisplayCircularView extends HTMLSnippetFieldDisplayCircularView

    # Default is to call `set` on the model any time a field input changes.
    events: {}


  # Collection View
  # ---------------
  #
  # For displaying individual collections (i.e., OLD text-like resources).

  class CollectionView extends ResourceView

    initialize: (options) ->
      super options
      @dummyFileModel = new FileModel()
      @filesCollection = new FilesCollection()
      @formsCollection = new FormsCollection()

    resourceName: 'collection'

    excludedActions: ['history', 'data', 'settings']

    controlsViewClass: CollectionControlsView

    resourceAddWidgetView: CollectionAddWidgetView

    getHeaderTitle: -> @getTruncatedTitleAndId()

    listenToEvents: ->
      super
      @listenTo @model, 'formsFetchedForDisplay', @displayForms
      @listenTo @model, 'displayReferencedFiles', @fetchReferencedFiles

      @listenTo @dummyFileModel, "searchStart", @fileSearchStart
      @listenTo @dummyFileModel, "searchEnd", @fileSearchEnd
      @listenTo @dummyFileModel, "searchFail", @fileSearchFail
      @listenTo @dummyFileModel, "searchSuccess", @fileSearchSuccess

    # The DisplayCollectionFilesControlView has asked us to display the files
    # that are referenced in the `content` value. First step is to get the id
    # values of the referenced files and then fetch them.
    fetchReferencedFiles: ->
      fileIds = []
      @$('.file-container').each (index, element) =>
        fileIds.push Number(@$(element).attr('data-id'))
      console.log fileIds
      search =
        filter: ["File", "id", "in", fileIds]
        order_by: ["File", "id", "desc" ]
      @dummyFileModel.search search

    fileSearchStart: ->

    fileSearchEnd: ->

    fileSearchFail: (error) ->
      console.log "we failed to fetch the files that are referenced by
        collection #{@model.get 'id'}"

    fileSearchSuccess: (responseJSON) ->
      if responseJSON.paginator.count > 0
        @displayFiles responseJSON.items

    displayFiles: (filesArray) ->
      @$('div.html div.file-container').each (index, element) =>
        $element = @$ element
        fileId = Number $element.attr('data-id')
        fileObject = _.findWhere filesArray, id: fileId
        if fileObject
          $element.addClass 'dative-resource-widget dative-shadowed-widget
            dative-paginated-item dative-widget-center ui-widget
            ui-widget-content ui-corner-all expanded'
          fileModel = new FileModel fileObject, collection: @filesCollection
          fileView = new FileView model: fileModel
          fileView.setElement $element
          fileView.render()
          @rendered fileView
        else
          $element.html "There is no file with id #{fileId}"
          console.log "TODO: warn user that we could not find a file with id
            #{fileId}"

    displayForms: (formsArray) ->
      # formsArray = @model.get 'forms'
      @$('div.html div.form-container').each (index, element) =>
        $element = @$ element
        formId = Number $element.attr('data-id')
        formObject = _.findWhere formsArray, id: formId
        if formObject
          $element.addClass 'dative-resource-widget dative-form-object
            dative-paginated-item dative-widget-center ui-corner-all'
          formModel = new FormModel formObject, collection: @formsCollection
          formView = new FormViewNoDuplicateAction model: formModel
          formView.setElement $element
          formView.render()
          @rendered formView
        else
          $element.html "There is no form with id #{formId}"

    # Return a string consisting of the value of the model's `title` attribute
    # truncated to 40 chars, and the model's id. Note: this is probably not
    # general enough a method to be in this base class.
    getTruncatedTitleAndId: ->
      title = @model.get 'title'
      id = @model.get 'id'
      if title
        truncatedTitle = title[0..35]
        if truncatedTitle isnt title then title = "#{truncatedTitle}..."
      else
        title = ''
      if id then "#{title} (id #{id})" else title

    # Attributes that are always displayed.
    primaryAttributes: [
      'title'
      'description'
      'type'
      'url'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'html'
      'markup_language'
      'source'
      'speaker'
      'elicitor'
      'date_elicited'
      'tags'
      'files'
      'enterer'
      'modifier'
      'datetime_entered'
      'datetime_modified'
      'UUID'
      'id'
    ]

    # Map attribute names to display view class names.
    attribute2displayView:
      datetime_modified: DateFieldDisplayView
      datetime_entered: DateFieldDisplayView
      date_elicited: DateFieldDisplayView
      speaker: SpeakerFieldDisplayView
      elicitor: ElicitorFieldDisplayView
      enterer: EntererFieldDisplayView
      modifier: ModifierFieldDisplayView
      source: SourceFieldDisplayView
      tags: ArrayOfRelatedTagsFieldDisplayView
      files: ArrayOfRelatedFilesFieldDisplayView
      html: MyHTMLSnippetFieldDisplayCircularView


