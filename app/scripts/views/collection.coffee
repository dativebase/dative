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


  class CollectionHTMLFieldDisplayView extends HTMLSnippetFieldDisplayCircularView

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
      @dummyFormModel = new FormModel()
      @filesCollection = new FilesCollection()
      @formsCollection = new FormsCollection()

      # Machinery for requesting referenced forms.

      # All of the form ids whose forms we have requested from the server.
      @formIdsRequested = []

      # Maps form ids to the form objects that we have received from the server.
      @formObjects = {}

      # An array of form ids that we are requesting in the current fetch, if
      # applicable.
      @formIdsInCurrentFetch = []

      # Array of form ids constituting the queue of form ids that we need
      # to fetch.
      @formIdsToFetchQueue = []

      # Set this to true when a search for forms is currently in progress.
      @formFetchInProgress = false

    resourceName: 'collection'

    excludedActions: ['history', 'data', 'settings']

    controlsViewClass: CollectionControlsView

    resourceAddWidgetView: CollectionAddWidgetView

    getHeaderTitle: -> @getTruncatedTitle()

    # Add the form ids in `formIdsToFetch` to our queue of forms to fetch
    # `@formIdsToFetchQueue`.
    addReferencedFormsToFetchQueue: (formIdsToFetch) ->
      for id in formIdsToFetch
        if id not in @formIdsRequested and id not in @formIdsToFetchQueue
          @formIdsToFetchQueue.push id
      if not @formFetchInProgress
        @fetchFormIdsInQueue()

    # Issue a SEARCH request looking for forms whose ids match those listed in
    # our queue `@formIdsToFetchQueue`.
    fetchFormIdsInQueue: ->
      @formIdsInCurrentFetch = (id for id in @formIdsToFetchQueue)
      # If there's nothing to fetch, abort.
      if @formIdsInCurrentFetch.length == 0
        return
      search =
        filter: ["Form", "id", "in", @formIdsInCurrentFetch]
        order_by: ["Form", "id", "desc" ]
      # Redefine our queue; this will probably be [], although the user may
      # have added new references between this statement and the first one in
      # this method.
      @formIdsToFetchQueue = (id for id in @formIdsToFetchQueue when id \
        not in @formIdsInCurrentFetch)
      @dummyFormModel.search search, null, false # `false` means no pagination
      @formFetchInProgress = true
      # Keep a record of the forms we have already requested.
      for id in @formIdsInCurrentFetch
        @formIdsRequested.push id

    formSearchStart: ->

    formSearchEnd: ->
      @formFetchInProgress = false

    formSearchFail: (responseJSON) ->
      console.log 'something went wrong when searching for forms by their id
        references.'
      console.log responseJSON

    formSearchSuccess: (responseJSON) ->
      retrievedIds = (f['id'] for f in responseJSON)
      for id in @formIdsInCurrentFetch
        # Mapping an id to `null` indicates an invalid id.
        if id not in retrievedIds
          @formObjects[id] = null
      for formObj in responseJSON
        @formObjects[formObj['id']] = formObj
      @model.trigger 'formObjectsChanged', @formObjects
      # Perform another fetch/search if we're not already.
      if not @formFetchInProgress then @fetchFormIdsInQueue()

    listenToEvents: ->
      super
      @listenTo @model, 'formsFetchedForDisplay', @displayForms
      @listenTo @model, 'displayReferencedFiles', @fetchReferencedFiles

      # The contents value is telling us what forms are referenced in it.
      @listenTo @model, 'addReferencedFormsToFetchQueue',
        @addReferencedFormsToFetchQueue

      @listenTo @dummyFileModel, "searchStart", @fileSearchStart
      @listenTo @dummyFileModel, "searchEnd", @fileSearchEnd
      @listenTo @dummyFileModel, "searchFail", @fileSearchFail
      @listenTo @dummyFileModel, "searchSuccess", @fileSearchSuccess

      @listenTo @dummyFormModel, "searchStart", @formSearchStart
      @listenTo @dummyFormModel, "searchEnd", @formSearchEnd
      @listenTo @dummyFormModel, "searchFail", @formSearchFail
      @listenTo @dummyFormModel, "searchSuccess", @formSearchSuccess

    # The DisplayCollectionFilesControlView has asked us to display the files
    # that are referenced in the `content` value. First step is to get the id
    # values of the referenced files and then fetch them.
    fetchReferencedFiles: ->
      fileIds = []
      @$('.file-container').each (index, element) =>
        fileIds.push Number(@$(element).attr('data-id'))
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
    getTruncatedTitle: ->
      title = @model.get 'title'
      id = @model.get 'id'
      if title
        truncatedTitle = title[0..35]
        if truncatedTitle isnt title then title = "#{truncatedTitle}..."
        title
      else if id
        "Collection #{id}"
      else
        "Unsaved Collection"

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
      html: CollectionHTMLFieldDisplayView


