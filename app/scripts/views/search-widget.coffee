define [
  './base'
  './resource'
  './search-add-widget'
  './search-field'
  './../models/search'
  './../models/form'
  './../collections/searches'
  './../templates/search-widget'
  './../utils/globals'
], (BaseView, ResourceView, SearchAddWidgetView, SearchFieldView, SearchModel,
  FormModel, SearchesCollection, searchWidgetTemplate, globals) ->

  class MySearchAddWidgetView extends SearchAddWidgetView

    # Return the array of resource names that this search add widget needs in
    # order for a search over the target resource to be created. Note that this
    # is an override of the super-class's method. This is because here
    # `@resourceName` alone (i.e., "search") is insufficient: we need to know
    # also what the target resource is, i.e., what we are searching over.
    relatedResourcesNeeded: ->
      key = "#{@targetResourceName}_search"
      if key of globals.relatedResources
        globals.relatedResources[key]
      else
        []


  # Search Widget
  # -------------
  #
  # A view that contains a SearchFieldView and buttons for
  # - performing the search (i.e., browsing the results),
  # - counting the search results, and
  # - saving the search.

  class SearchFieldViewNoLabel extends SearchFieldView

    showLabel: false


  class SearchWidgetView extends ResourceView

    # Change the following  attributes in sub-classes. These indicate which
    # resource is being searched.
    targetResourceName: 'form'
    targetModelClass: FormModel
    searchModelClass: SearchModel
    searchFieldViewClass: SearchFieldViewNoLabel

    resourceName: 'search'

    tagName: 'div'
    className: 'dative-search-widget dative-shadowed-widget
      dative-widget-center ui-widget ui-widget-content ui-corner-all'
    template: searchWidgetTemplate

    events:
      'click .search-button': 'search'
      'click .count-button': 'count'
      'click .save-button': 'save'
      'click .hide-search-widget': 'hideMe'
      'click .help': 'openHelp'
      'click .browse-return': 'browseReturn'
      'keydown': 'keyboardShortcuts'

    keyboardShortcuts: (event) ->
      event.stopPropagation()
      switch event.which
        when 27 then @hideMe()

    # Browse the results of the search in the search widget. Here we trigger a
    # Backbone event that the master `AppView` instance listens for and then
    # refreshes the relevant resources browse view.
    search: ->
      Backbone.trigger(
        "request:#{@targetResourceNamePlural}BrowseSearchResults",
        search: @model.get('search'))

    # Initiate a search request in order to count how many results the
    # currently specified search would return and display that count in a
    # notifier.
    count: ->
      paginator = {page: 1, items_per_page: 1}
      @listenToOnce @targetModel, 'searchSuccess', @displayCount
      @targetModel.search @model.get('search'), paginator

    # Trigger the notifier into displaying the search results count.
    displayCount: (searchResponse) ->
      count = searchResponse.paginator.count
      Backbone.trigger 'resourceCountSuccess', @targetResourceName, count

    # Save the search that is currently held in the search widget.
    save: ->
      searchesCollection = new SearchesCollection()
      @newSearchModel =
        new SearchModel(@model.attributes, {collection: searchesCollection})
      Backbone.trigger 'showResourceModelInDialog', @newSearchModel, 'search'

    # Trigger an event so that the superview `ResourcesView` instance will take
    # us back to browsing all resources.
    browseReturn: -> @trigger 'browseReturn'

    hideMe: ->
      @trigger 'hideMe'

    # Tell the Help dialog to open itself and search for "searching `@targetResourceNamePlural`" and
    # scroll to the second match. WARN: this is brittle because if the help
    # HTML changes, then the second match may not be what we want...
    openHelp: ->
      Backbone.trigger(
        'helpDialog:openTo',
        searchTerm: "searching #{@targetResourceNamePlural}"
        scrollToIndex: 1
      )

    initialize: ->
      @targetResourceNamePlural = @utils.pluralize @targetResourceName
      @targetResourceNamePluralCapitalized =
        @utils.capitalize @targetResourceNamePlural
      @mixinSearchAddWidgetView()
      @model = new @searchModelClass()
      @targetModel = new @targetModelClass()
      @listenToEvents()

    # Appropriate a subset of the methods of `SearchAddWidgetView`.
    mixinSearchAddWidgetView: ->
      methodsWeWant = [
        'relatedResourcesNeeded'
        'checkForRelatedResourceData'
        'getNewResourceData'
        'getNewResourceDataStart'
        'getNewResourceDataEnd'
        'getNewResourceDataSuccess'
        'getNewResourceDataFail'
        'getOptions'
      ]
      for method in methodsWeWant
        @[method] = MySearchAddWidgetView::[method]

    # We may have `SearchWidgetView`s over various resources (e.g., forms,
    # files, etc.). Therefore, we need a different global attribute for each
    # type of search widget so that we can know which attributes to search over
    # for forms and which for files and not get them mixed up. This overwrites a
    # method in `ResourceAddWidgetView`.
    getGlobalDataAttribute: ->
      "#{@resourceName}Over#{@targetResourceNamePluralCapitalized}Data"

    render: ->
      if @checkForRelatedResourceData() is 'exit' then return
      @searchFieldView = @getSearchFieldView()
      @html()
      @guify()
      @renderSearchFieldView()
      @listenToEvents()
      @

    # TODO: can this safely be deleted?
    x: ->
      if not @weHaveNewResourceData()
        @model.getNewResourceData() # Success in this request will call `@render()`
        return

    getSearchFieldView: ->
      new @searchFieldViewClass
        resource: @targetResourceNamePlural
        attribute: 'search'
        model: @model
        options: @getOptions()

    listenToEvents: ->
      # Events specific to an OLD backend and the request for the data needed
      # to create a resource.
      @listenTo @model, "getNewSearchDataStart",
        @getNewResourceDataStart
      @listenTo @model, "getNewSearchDataEnd",
        @getNewResourceDataEnd
      @listenTo @model, "getNewSearchDataSuccess",
        @getNewResourceDataSuccess
      @listenTo @model, "getNewSearchDataFail",
        @getNewResourceDataFail
      if @searchFieldView
        @listenTo @searchFieldView, 'search', @search

    renderSearchFieldView: ->
      @$('ul.primary-data').append @searchFieldView.render().el
      @rendered @searchFieldView

    html: ->
      context =
        targetResourceNamePlural: @targetResourceNamePlural
        targetResourceNamePluralCapitalized:
          @targetResourceNamePluralCapitalized
      @$el.html @template(context)

    guify: ->
      @buttonify()
      @tooltipify()
      @$el.css 'border-color': @constructor.jQueryUIColors().defBo

    buttonify: ->
      @$('.dative-widget-header button').button()
      @$('.button-only-fieldset button').button()

      # Make all of righthand-side buttons into jQuery buttons and set the
      # position of their tooltips programmatically based on their
      # position/index.
      @$(@$('.button-container-right button').get().reverse())
        .each (index, element) =>
          leftOffset = (index * 35) + 10
          @$(element)
            .button()
            .tooltip
              position:
                my: "left+#{leftOffset} center"
                at: "right center"
                collision: "flipfit"

    # Make the `title` attributes of the inputs/controls into jQueryUI tooltips.
    tooltipify: ->
      @$('.dative-widget-header .hide-search-widget.dative-tooltip')
          .tooltip position: @tooltipPositionLeft('-20')
      @$('ul.button-only-fieldset button.dative-tooltip').tooltip()

