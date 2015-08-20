define [
  './input'
  './resource'
  './resource-as-row'
  './related-resource-representation'
  './selected-resource-wrapper'
  './../models/resource'
  './../collections/resources'
  './../templates/resource-select-via-search-input'
], (InputView, ResourceView, ResourceAsRowView,
  RelatedResourceRepresentationView, SelectedResourceWrapperView,
  ResourceModel, ResourcesCollection, resourceSelectViaSearchInputTemplate) ->

  # Resource Select Via Search Input View
  # -------------------------------------
  #
  # A view for selecting a particular resource (say, for a many-to-one
  # relation) by searching for it in a search input. This input performs a
  # "smart" search; i.e., it tries to understand what the user may be searching
  # for without exposing a complex interface.
  #
  # Note: this view will only work when searching over resources that expose a
  # server-side search interface. For the OLD, the only such resources are
  # currently:
  #
  # - forms (and their backups)
  # - files
  # - collections (and their backups)
  # - form searches
  # - sources
  # - languages

  class ResourceSelectViaSearchInputView extends InputView

    # Change the following attributes in subclasses.

    # The name of the resource being searched, e.g., 'file', 'source'.
    resourceName: 'resource'

    # The class for generating Backbone models for the resources returned by
    # the search request.
    resourceModelClass: ResourceModel

    # The class for generating a Backbone collection to be given to the models
    # generated using the class above.
    resourcesCollectionClass: ResourcesCollection

    # This is the class that is used to display the resources that match the
    # search. It should be a subclass of `ResourceAsRowView` since the search
    # results are displayed as a table.
    resourceAsRowViewClass: ResourceAsRowView

    # This is the class that is used to display the *selected* resource.
    selectedResourceViewClass: RelatedResourceRepresentationView

    # This class, if valuated, will be used to wrap the
    # `@selectedResourceViewClass` instance; this class provides the "deselect"
    # button.
    selectedResourceWrapperViewClass: SelectedResourceWrapperView

    # This class is the one that is used to display a *selected* resource in a
    # dialog box. This class is needed for the default
    # `@selectedResourceViewClass`, i.e., for the
    # `RelatedResourceRepresentationView`. This should be a subclass of
    # `ResourceView`.
    resourceViewClass: ResourceView

    template: resourceSelectViaSearchInputTemplate

    initialize: (context) ->
      super context
      @selectedResourceViewRendered = false

      # This will hold the resource model that the user selects (/ has
      # selected).
      @selectedResourceModel = null

      # We use this instance simply for its methods: to get search options data
      # and to perform searches.
      @resourceModel = new @resourceModelClass()

      @getNames()
      @searchResultsTableVisible = false
      @searchResultsCount = 0
      @setStateBasedOnSelectedValue()

    refresh: (@context) ->
      @setStateBasedOnSelectedValue()
      @selectedResourceViewRendered = false
      @render()

    # Get `@resourceName` in various forms.
    getNames: ->
      @resourceNamePlural = @utils.pluralize @resourceName
      @resourceNameCapitalized = @utils.capitalize @resourceName
      @serverSideResourceNameCapitalized =
        @getServerSideResourceNameCapitalized @resourceNameCapitalized
      @resourceNamePluralCapitalized = @utils.capitalize @resourceNamePlural

    # Override this in sub-classes as necessary, e.g., in a search interface
    # for form searches where 'Search' is wrong and 'FormSearch' is correct.
    getServerSideResourceNameCapitalized: (resourceNameCapitalized) ->
      resourceNameCapitalized

    # If we have a selected value, cause it to be displayed and the search
    # interface to not be displayed; if not, do the opposite.
    setStateBasedOnSelectedValue: ->
      if @context.value
        @selectedResourceModel = new @resourceModelClass(@context.value)
        @searchInterfaceVisible = false
        @selectedResourceViewVisible = true
      else
        @searchInterfaceVisible = true
        @selectedResourceViewVisible = false

    getMultiSelect: -> false

    render: ->
      @context.multiSelect = @getMultiSelect()

      @context.resourceNameHuman = @utils.snake2regular @context.attribute
      @context.resourceNameHumanCapitalized =
        (@utils.capitalize(w) for w in @context.resourceNameHuman.split(' ')).join ' '
      super
      @buttonify()
      @tooltipify()
      @renderHeaderView()
      @searchResultsTable()
      @searchInterfaceVisibility()
      @selectedVisibility()
      @

    # Render/display any selected resource(s).
    selectedVisibility: ->
      if @weHaveSelected()
        if @selectedResourceViewRendered
          @showSelectedResourceView()
        else
          @renderSelectedResourceView()
      else
        @selectedResourceViewVisibility()

    # Return `true` if we have something selected. This is its own function
    # because in a subclass we may want to check for a non-empty array.
    weHaveSelected: -> @selectedResourceModel?

    searchResultsTable: ->
      @$('.resource-results-via-search-table-wrapper')
        .css 'border-color': @constructor.jQueryUIColors().defBo
      @searchResultsTableVisibility()

    closeCurrentSelectedResourceView: ->
      if @selectedResourceView
        @selectedResourceView.close()
        @closed @selectedResourceView

    # This is a function that `@selectedResourceView` *may* use to display
    # itself in string form. Override it for resource-specific behaviour.
    resourceAsString: (resource) -> resource.id

    # Return an instance of `@selectedResourceViewClass` for the selected
    # resource. Note that this method assumes that this view class is a
    # sub-class of `RelatedResourceRepresentationView`, hence the particular
    # params passed on initialization. Override this method on sub-classes.
    getSelectedResourceView: ->
      params =
        value: @selectedResourceModel.attributes
        class: 'field-display-link dative-tooltip'
        resourceAsString: @resourceAsString
        valueFormatter: (v) -> v
        resourceName: @resourceName
        attributeName: @context.attribute
        resourceModelClass: @resourceModelClass
        resourcesCollectionClass: @resourcesCollectionClass
        resourceViewClass: null
        model: @getModelForSelectedResourceView()
      if @selectedResourceWrapperViewClass
        new @selectedResourceWrapperViewClass @selectedResourceViewClass, params
      else
        new @selectedResourceViewClass params

    getModelForSelectedResourceView: -> @model

    # Render the view for the resource that the user has selected.
    renderSelectedResourceView: ->
      @closeCurrentSelectedResourceView()
      @selectedResourceView = @getSelectedResourceView()
      $container = @$('.selected-resource-display-container').first()
      @selectedResourceView.setElement $container
      @selectedResourceView.render()
      @rendered @selectedResourceView
      @listenToSelectedResourceView()
      @selectedResourceViewVisible = true
      @selectedResourceViewRendered = true
      @containerAppearance $container
      @selectedResourceViewVisibility()
      @$('button.deselect').first().focus().select()
      @renderSelectedResourceViewPost()

    # Do something special after the view for the selected resource has been
    # rendered.
    renderSelectedResourceViewPost: ->

    # Do something to change the appearance of the container for the selected
    # resource, if needed.
    containerAppearance: ($container) ->

    listenToSelectedResourceView: ->
      @listenTo @selectedResourceView, 'deselect',
        @deselectCurrentlySelectedResourceModel

      # Sometimes we want to allow the view for the selected resource to tell
      # us to set attributes on our model. Consider the case where the selected
      # attribute is a parent file displayed with a specialized view; if a user
      # clicks "set start" on that view, then this method can be triggered in
      # order to set the `start` value to a certain float.
      @listenTo @selectedResourceView, 'setAttribute', @setAttribute

    setAttribute: (attr, val) ->
      @model.trigger 'setAttribute', attr, val

    setSelectedToModel: (resourceAsRowView) ->
      @model.set @context.attribute, resourceAsRowView.model.attributes

    unsetSelectedFromModel: ->
      @model.set @context.attribute, @model.defaults()[@context.attribute]

    deselectCurrentlySelectedResourceModel: ->
      @unsetSelectedFromModel()
      @selectedResourceModel = null
      @trigger 'validateMe'
      if @searchResultsCount > 0 then @showSearchResultsTableAnimate()
      @showSearchInterfaceAnimate (=> @focusAndSelectSearchTerm())
      @hideSelectedResourceViewAnimateCheck(=> @closeCurrentSelectedResourceView())

    focusAndSelectSearchTerm: ->
      @$('[name=search-term]').first().focus().select()

    # Set the relevant attribute of our model to the model of the
    # passed-in `resourceAsRowView`
    selectResourceAsRowView: (resourceAsRowView) ->
      @setSelectedToModel resourceAsRowView
      @selectedResourceModel = resourceAsRowView.model
      @trigger 'validateMe'
      @hideSearchResultsTableAnimate()
      @hideSearchInterfaceAnimate()
      @renderSelectedResourceView()

    tooltipify: ->
      @$('.dative-tooltip')
        .tooltip position: @tooltipPositionLeft('-200')

    events:
      'click .perform-search': 'performSearch'
      'keydown .resource-select-via-search-input-input': 'keydown'

    keydown: (event) -> if event.which is 13 then @performSearch()

    listenToEvents: ->
      super
      @listenTo @resourceModel, 'searchSuccess', @searchSuccess
      @listenTo @resourceModel, 'searchStart', @searchStart
      @listenTo @resourceModel, 'searchEnd', @searchEnd
      @listenTo @resourceModel, 'searchFail', @searchFail

    itemsPerPage: 100

    resourceAsRowViews: []

    closeResourceAsRowViews: ->
      while @resourceAsRowViews.length
        view = @resourceAsRowViews.pop()
        view.close()
        @closed view

    getSearchResultsHeader: ->
      header = ['<div class="resource-as-row-row">']
      if @resourceAsRowViewClass::orderedAttributes
        iterator = @resourceAsRowViewClass::orderedAttributes
      else
        iterator = _.keys (new @resourceModelClass()).attributes
      for attribute in iterator
        header.push "<div class='resource-as-row-cell
          resource-as-row-attr-#{attribute}'
          >#{@utils.snake2regular attribute}</div>"
      header.push '</div>'
      header.join ''

    searchSuccess: (responseJSON) ->
      @showSearchResultsTableAnimateCheck()
      @closeResourceAsRowViews()
      @searchResultsCount = @reportMatchesFound responseJSON
      if @searchResultsCount > 0
        @$('div.resource-results-via-search-table')
          .html @getSearchResultsRows(responseJSON)
          .scrollLeft 0
        @$('button.select').first().focus()
      else
        @focusAndSelectSearchTerm()

    reportMatchesFound: (responseJSON) ->
      count = responseJSON.paginator.count
      itemsPerPage = responseJSON.paginator.items_per_page
      noun = if count is 1 then 'match' else 'matches'
      @$('span.results-count').text "#{count} #{noun}"
      if count > 0
        showing = if (count < itemsPerPage) then count else itemsPerPage
        @$('span.results-showing-count').text "showing #{showing}"
      count

    # Render the header view. This is a `@resourceAsRowViewClass` instance that
    # contains dummy data (formatted attribute names); it constitutes the
    # "header" at the top of the search results table.
    renderHeaderView: ->
      headerObject = {}
      for attr in @resourceAsRowViewClass::orderedAttributes
        headerObject[attr] = @utils.snake2regular attr
      @headerModel = new @resourceModelClass headerObject
      @headerView = new @resourceAsRowViewClass
        model: @headerModel
        isHeaderRow: true
      @headerView.render()
      @rendered @headerView

    getSearchResultsRows: (responseJSON) ->
      fragment = document.createDocumentFragment()
      fragment.appendChild @headerView.el
      for modelObject in responseJSON.items
        resourceModel = new @resourceModelClass modelObject
        resourceAsRowView = new @resourceAsRowViewClass
          model: resourceModel
          query: @query
        @resourceAsRowViews.push resourceAsRowView
        resourceAsRowView.render()
        @rendered resourceAsRowView
        @listenToResourceAsRow resourceAsRowView
        fragment.appendChild resourceAsRowView.el
      fragment

    listenToResourceAsRow: (resourceAsRowView) ->
      @listenTo resourceAsRowView, 'selectMe', @selectResourceAsRowView

    onClose: -> @selectedResourceViewRendered = false

    searchFail: (errorMessage) ->
      Backbone.trigger "search#{@resourceName}Fail", errorMessage

    searchStart: ->
      @disableInterface()
      @spin()

    searchEnd: ->
      @enableInterface()
      @stopSpin()

    disableInterface: ->
      @$('button').button 'disable'
      @$('input').prop 'disabled', true

    enableInterface: ->
      @$('button').button 'enable'
      @$('input').prop 'disabled', false

    spinnerOptions: ->
      options = super
      options.top = '50%'
      options.left = '130%'
      options.color = @constructor.jQueryUIColors().defCo
      options

    spin: -> @$('button.perform-search').first().spin @spinnerOptions()

    stopSpin: -> @$('button.perform-search').first().spin false

    getGlobalDataAttribute: -> "search#{@resourceNamePluralCapitalized}Data"

    performSearch: ->
      searchTerm = @$('[name=search-term]').val()
      if @weHaveNewResourceData()
        paginator =
          page: 1
          items_per_page: @itemsPerPage
        @query = @getSmartQuery searchTerm
        @resourceModel.search @query, paginator
      else
        @listenToOnce @resourceModel,
          "getNew#{@resourceNameCapitalized}SearchDataSuccess",
          @getNewResourceSearchDataSuccess
        @listenToOnce @resourceModel,
          "getNew#{@resourceNameCapitalized}SearchDataFail",
          @getNewResourceSearchDataFail
        @resourceModel.getNewSearchData()

    # These are the `[<attribute]`s or `[<attribute>, <subattribute>]`s that we
    # "smartly" search over. Extend this array in sub-classes to cover salient
    # attributes, relative to the resource being searched over.
    smartStringSearchableFileAttributes: [
      ['id']
    ]

    # Returns `true` if `searchTerms` is an array containing a string that only
    # contains digits; here we assume the user is searching for a numeric id.
    isIdSearch: (searchTerms) ->
      searchTerms.length is 1 and searchTerms[0].match /^[0-9]+$/

    # Return a query object for intelligently searching over (OLD) file
    # resources, given the string `searchTerm`. Here we try to guess what the
    # user probably wants their search expression to do.
    getSmartQuery: (searchTerm) ->
      searchTerms = searchTerm.split /\s+/
      order_by = [@serverSideResourceNameCapitalized, 'id', 'desc']
      if @isIdSearch searchTerms
        filter = @getIdSearchFilter searchTerms
      else
        filter = @getGeneralSearchFilter searchTerms
      order_by: order_by
      filter: filter

    getIdSearchFilter: (searchTerms) ->
      [@serverSideResourceNameCapitalized, 'id', '=', parseInt(searchTerms[0])]

    # Return a search filter over the relevant resource such that what is
    # returned is all resources such that all of the search terms in
    # `searchTerms` match (substring-wise) at least one of the
    # "string-searchable" attributes listed in `@smartStringSearchableFileAttributes`.
    getGeneralSearchFilter: (searchTerms) ->
      filter = ['and']
      complement = @getGeneralSearchFilterComplement()
      for searchTerm in searchTerms
        conjunct = ['or']
        subcomplement = []
        for attributeSet in @smartStringSearchableFileAttributes
          subfilter = [@serverSideResourceNameCapitalized]
          for attribute in attributeSet
            subfilter.push attribute
          subfilter.push 'like'
          if searchTerm is '' # An empty search term means "get everything"
            subfilter.push '%'
          else
            subfilter.push "%#{searchTerm}%"
          subcomplement.push subfilter
        conjunct.push subcomplement
        complement.push conjunct
      filter.push complement
      filter

    # Add some required filters here for specific resources, e.g., "must be
    # grammatical"
    getGeneralSearchFilterComplement: -> []

    getNewResourceSearchDataSuccess: (data) ->
      @storeOptionsDataGlobally data
      @performSearch()

    getNewResourceSearchDataFail: (error) ->
      console.log "Sorry, we were not able to retrieve the data for creating a
        search over #{@resourceNamePlural}"


    # Search Results Table
    ############################################################################

    # Make the search results table visible, or not, depending on state.
    searchResultsTableVisibility: ->
      if @searchResultsTableVisible
        @showSearchResultsTable()
      else
        @hideSearchResultsTable()

    showSearchResultsTable: ->
      @searchResultsTableVisible = true
      @$('.resource-results-via-search-table-wrapper').first().show()

    hideSearchResultsTable: ->
      @searchResultsTableVisible = false
      @$('.resource-results-via-search-table-wrapper').first().hide()

    toggleSearchResultsTable: ->
      if @searchResultsTableVisible
        @hideSearchResultsTable()
      else
        @showSearchResultsTable()

    showSearchResultsTableAnimateCheck: ->
      if @$('.resource-results-via-search-table-wrapper').is ':hidden'
        @showSearchResultsTableAnimate()

    showSearchResultsTableAnimate: ->
      @searchResultsTableVisible = true
      @$('.resource-results-via-search-table-wrapper').first().slideDown()

    hideSearchResultsTableAnimate: ->
      @searchResultsTableVisible = false
      @$('.resource-results-via-search-table-wrapper').first().slideUp()

    toggleSearchResultsTableAnimate: ->
      if @searchResultsTableVisible
        @hideSearchResultsTableAnimate()
      else
        @showSearchResultsTableAnimate()


    # Search Interface
    ############################################################################

    # Make the search interface visible, or not, depending on state.
    searchInterfaceVisibility: ->
      if @searchInterfaceVisible
        @showSearchInterface()
      else
        @hideSearchInterface()

    toggleSearchInterface: ->
      if @searchInterfaceVisible
        @hideSearchInterface()
      else
        @showSearchInterface()

    toggleSearchInterfaceAnimate: ->
      if @searchInterfaceVisible
        @hideSearchInterfaceAnimate()
      else
        @showSearchInterfaceAnimate()

    hideSearchInterfaceAnimate: ->
      @searchInterfaceVisible = false
      @$('.resource-select-via-search-interface').first().slideUp()

    showSearchInterfaceAnimate: (complete=->) ->
      @searchInterfaceVisible = true
      @$('.resource-select-via-search-interface').first().slideDown
        complete: complete

    hideSearchInterface: ->
      @searchInterfaceVisible = false
      @$('.resource-select-via-search-interface').first().hide()

    showSearchInterface: ->
      @searchInterfaceVisible = true
      @$('.resource-select-via-search-interface').first().show()


    # Selected Resource View
    ############################################################################

    # Make the selected resource view visible, or not, depending on state.
    selectedResourceViewVisibility: ->
      if @selectedResourceViewVisible
        @showSelectedResourceView()
      else
        @hideSelectedResourceView()

    showSelectedResourceView: ->
      @selectedResourceViewVisible = true
      @$('.selected-resource-display-container').first().show()

    hideSelectedResourceView: ->
      @selectedResourceViewVisible = false
      @$('.selected-resource-display-container').first().hide()

    toggleSelectedResourceView: ->
      if @selectedResourceViewVisible
        @hideSelectedResourceView()
      else
        @showSelectedResourceView()

    showSelectedResourceViewAnimateCheck: ->
      if @$('.selected-resource-display-container').is ':hidden'
        @showSelectedResourceViewAnimate()

    showSelectedResourceViewAnimate: ->
      @selectedResourceViewVisible = true
      @$('.selected-resource-display-container').first().slideDown()

    hideSelectedResourceViewAnimate: (complete=->) ->
      @selectedResourceViewVisible = false
      @$('.selected-resource-display-container').first().slideUp
        complete: complete

    hideSelectedResourceViewAnimateCheck: (complete=->) ->
      if @$('.selected-resource-display-container').is ':visible'
        @hideSelectedResourceViewAnimate complete

    toggleSelectedResourceViewAnimate: ->
      if @selectedResourceViewVisible
        @hideSelectedResourceViewAnimate()
      else
        @showSelectedResourceViewAnimate()

