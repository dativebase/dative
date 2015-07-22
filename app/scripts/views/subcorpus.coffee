define [
  './resource'
  './subcorpus-controls'
  './subcorpus-add-widget'
  './search'
  './field-display'
  './person-field-display'
  './date-field-display'
  './object-with-name-field-display'
  './array-of-objects-with-name-field-display'
  './../models/search'
], (ResourceView, SubcorpusControlsView, SubcorpusAddWidgetView, SearchView,
  FieldDisplayView, PersonFieldDisplayView, DateFieldDisplayView,
  ObjectWithNameFieldDisplayView, ArrayOfObjectsWithNameFieldDisplayView,
  SearchModel) ->

  class FormSearchDisplayView extends FieldDisplayView

    getContext: ->
      context = super
      try
        context.value = "<a
          href='javascript:;'
          class='field-display-link
            subcorpus-form-search-display
            dative-tooltip'
          title='click here to view this form search in the page'
          >#{context.value.name}</a>"
      catch
        context.value = ''
      context

    events:
      'click a.subcorpus-form-search-display': 'displayFormSearch'

    listenToEvents: ->
      super
      if @model then @listenToModel()

    listenToModel: ->
      @listenTo @model, 'fetchSearchSuccess', @fetchSearchSuccess

    # Cause this form search to be displayed in a dialog box.
    displayFormSearch: ->
      @model = new SearchModel()
      @listenToModel()
      @model.fetchResource @context.model.get('form_search').id

    fetchSearchSuccess: (searchObject) ->
      @model.set searchObject
      formSearchView = new SearchView(model: @model)
      Backbone.trigger 'showResourceInDialog', formSearchView, @$el

    guify: ->
      @$('.dative-tooltip').tooltip()


  # Subcorpus View
  # --------------
  #
  # For displaying individual subcorpora.

  class SubcorpusView extends ResourceView

    resourceName: 'subcorpus'

    resourceNameHumanReadable: => 'corpus'

    resourceAddWidgetView: SubcorpusAddWidgetView

    excludedActions: ['history', 'data']

    controlsViewClass: SubcorpusControlsView

    # Attributes that are always displayed.
    primaryAttributes: [
      'name'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'description'
      'content'
      'tags'
      'form_search'
      'enterer'
      'modifier'
      'datetime_entered'
      'datetime_modified'
      'files'
      'UUID'
      'id'
    ]

    attribute2displayView:
      tags: ArrayOfObjectsWithNameFieldDisplayView
      form_search: FormSearchDisplayView
      enterer: PersonFieldDisplayView
      modifier: PersonFieldDisplayView
      datetime_entered: DateFieldDisplayView
      datetime_modified: DateFieldDisplayView
      files: ArrayOfObjectsWithNameFieldDisplayView

    getHeaderTitle: ->
      if @model.get('id') then "Corpus #{@model.get 'id'}" else "New Corpus"

