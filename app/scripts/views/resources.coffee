define [
  './base'
  './resource'
  './exporter-dialog'
  './pagination-menu-top'
  './pagination-item-table'
  './subcorpus'
  './../collections/resources'
  './../models/resource'
  './../utils/paginator'
  './../utils/globals'
  './../templates/resources'
], (BaseView, ResourceView, ExporterDialogView, PaginationMenuTopView,
  PaginationItemTableView, SubcorpusView, ResourcesCollection, ResourceModel,
  Paginator, globals, resourcesTemplate) ->

  # Resources View
  # ---------------
  #
  # Displays a collection of resources (e.g., FieldDB datums or OLD forms,
  # searches, phonologies, etc.) for browsing, with pagination. Also contains a
  # ResourceView instance (with a model that hasn't been saved on the server)
  # for creating new resources within the resources browse interface.
  #
  # This view is intended to be subclassed and parameterized minimally in order
  # to provide browsing and a SCRUD interface for various FieldDB/OLD resources.

  class ResourcesView extends BaseView

    # Override these four attributes in sub-classes.

    # `@resourceName` should be a singular uncapitalized noun denoting the type
    # of resource handled by this resources view. Capitalized and pluralized
    # counterparts are created dynamically.
    resourceName: 'resource'

    # `@resourceView` is a class that displays a single resource, it is
    # expected that this view will contain an update/add sub-view for updating
    # the resource.
    resourceView: ResourceView

    # A Backbone collection, and model for the resources.
    resourcesCollection: ResourcesCollection
    resourceModel: ResourceModel

    template: resourcesTemplate

    initialize: (options) ->
      @resourceNameCapitalized = @utils.capitalize @resourceName
      @resourceNamePlural = @utils.pluralize @resourceName
      @resourceNameHuman = @utils.camel2regular @resourceName
      @resourceNamePluralHuman = @utils.camel2regular @resourceNamePlural
      @resourceNamePluralCapitalized = @utils.capitalize @resourceNamePlural
      @enumerateResources = options?.enumerateResources or false
      @getGlobalsResourcesDisplaySettings()
      @focusedElementIndex = null
      @resourceViews = [] # holds a ResourceView instance for each ResourceModel in ResourcesCollection
      @paginationItemTableViews = [] # if `@enumerateResources` is true, then this holds an enumeration/pagination superview for each resource view.
      @renderedResourceViews = [] # references to the ResourceView instances that are rendered
      @weShouldFocusFirstAddViewInput = false # AppView sets this to True when you click Resources > Add
      @fetchCompleted = false
      @fetchResourcesLastPage = false # This is set to true when we want to fetch the last page immediately after fetching the first one.
      @lastFetched = # We store this to help us prevent redundant requests to the server for all resources.
        serverName: ''
      @paginator = new Paginator page=1, items=0, itemsPerPage=@itemsPerPage
      @paginationMenuTopView = new PaginationMenuTopView paginator: @paginator # This handles the UI for the items-per-page select, the first, prevous, next buttons, etc.
      @collection = new @resourcesCollection()
      @newResourceView = @getNewResourceView()
      @resourceSearchView = @getResourceSearchView()
      @exporterDialog = new ExporterDialogView()
      @newResourceViewVisible = false
      @resourceSearchViewVisible = false
      @resourceSearchViewRendered = false
      @listenToEvents()

    onClose: ->
      @newResourceViewRendered = false
      @resourceSearchViewRendered = false

    events:
      'focus input, textarea, .ui-selectmenu-button, button, .ms-container': 'inputFocused'
      'focus .dative-resource-widget': 'resourceFocused'
      'click .expand-all': 'expandAllResources'
      'click .collapse-all': 'collapseAllResources'
      'click .new-resource': 'showNewResourceViewAnimate'
      'click .resources-browse-help': 'openResourcesBrowseHelp'
      'click .toggle-all-labels': 'toggleAllLabels'
      'click .toggle-search': 'toggleResourceSearchViewAnimate'
      'click .corpus-display': 'displayCorpus'
      'keydown': 'keyboardShortcuts'
      'keyup': 'keyup'
      # @$el is enclosed in top and bottom invisible divs. These allow us to
      # close-circuit the tab loop and keep focus in the view.
      'focus .focusable-top':  'focusLastElement'
      'focus .focusable-bottom':  'focusFirstElement'

    displayCorpus: ->
      @corpusView = new SubcorpusView model: @corpus
      Backbone.trigger 'showResourceInDialog', @corpusView, @$el

    render: (taskId) ->
      @html()
      @matchHeights()
      @guify()
      @refreshHeader()
      @renderPaginationMenuTopView()
      @renderNewResourceView()
      @renderResourceSearchView()
      @renderExporterDialogView()
      @newResourceViewVisibility()
      @resourceSearchViewVisibility()
      if @weNeedToFetchResourcesAgain()
        @fetchResourcesLastPage = true
        @fetchResourcesPageToCollection()
      else
        @refreshPage()
      @listenToEvents()
      @setFocus()
      @$('#dative-page-body').scroll => @closeAllTooltips()
      Backbone.trigger 'longTask:deregister', taskId
      @

    renderExporterDialogView: ->
      @exporterDialog.setElement(@$('#exporter-dialog-container'))
      @exporterDialog.render()
      @rendered @exporterDialog

    html: ->
      @$el.html @template
        resourceName: @resourceName
        resourceNameHuman: @utils.camel2regular @resourceName
        resourceNamePlural: @resourceNamePlural
        resourceNamePluralHuman: @resourceNamePluralHuman
        pluralizeByNum: @utils.pluralizeByNum
        paginator: @paginator
        searchable: @searchable
        canCreateNew: @getCanCreateNew()

    listenToEvents: ->
      super

      @listenTo Backbone, "fetch#{@resourceNamePluralCapitalized}Start",
        @fetchResourcesStart
      @listenTo Backbone, "fetch#{@resourceNamePluralCapitalized}End",
        @fetchResourcesEnd
      @listenTo Backbone, "fetch#{@resourceNamePluralCapitalized}Fail",
        @fetchResourcesFail
      @listenTo Backbone, "fetch#{@resourceNamePluralCapitalized}Success",
        @fetchResourcesSuccess

      @listenTo Backbone, "destroy#{@resourceNameCapitalized}Success",
        @destroyResourceSuccess
      @listenTo Backbone, "duplicate#{@resourceNameCapitalized}",
        @duplicateResource
      @listenTo Backbone, "duplicate#{@resourceNameCapitalized}Confirm",
        @duplicateResourceConfirm

      @listenTo Backbone, "update#{@resourceNameCapitalized}Fail",
        @scrollToFirstValidationError
      @listenTo Backbone, "add#{@resourceNameCapitalized}Fail",
        @scrollToFirstValidationError

      @listenTo Backbone, 'openExporterDialog', @openExporterDialog

      @listenTo @paginationMenuTopView, 'paginator:changeItemsPerPage',
        @changeItemsPerPage
      @listenTo @paginationMenuTopView, 'paginator:showFirstPage',
        @showFirstPage
      @listenTo @paginationMenuTopView, 'paginator:showLastPage', @showLastPage
      @listenTo @paginationMenuTopView, 'paginator:showPreviousPage',
        @showPreviousPage
      @listenTo @paginationMenuTopView, 'paginator:showNextPage', @showNextPage
      @listenTo @paginationMenuTopView, 'paginator:showThreePagesBack',
        @showThreePagesBack
      @listenTo @paginationMenuTopView, 'paginator:showTwoPagesBack',
        @showTwoPagesBack
      @listenTo @paginationMenuTopView, 'paginator:showOnePageBack',
        @showOnePageBack
      @listenTo @paginationMenuTopView, 'paginator:showOnePageForward',
        @showOnePageForward
      @listenTo @paginationMenuTopView, 'paginator:showTwoPagesForward',
        @showTwoPagesForward
      @listenTo @paginationMenuTopView, 'paginator:showThreePagesForward',
        @showThreePagesForward

      @listenToNewResourceView()
      if @searchable then @listenToResourceSearchView()

    listenToResourceSearchView: ->
      @listenTo @resourceSearchView, 'hideMe', @hideResourceSearchViewAnimate

    listenToNewResourceView: ->
      @listenTo @newResourceView, "new#{@resourceNameCapitalized}View:hide",
        @hideNewResourceViewAnimate
      @listenTo @newResourceView.model, "add#{@resourceNameCapitalized}Success",
        @newResourceAdded

    scrollToFirstValidationError: (error, resourceModel) ->
      if resourceModel.id
        selector = "##{resourceModel.cid} .dative-field-validation-container"
      else
        selector = ".new-resource-view .dative-field-validation-container"
      $firstValidationError = @$(selector).filter(':visible').first()
      if $firstValidationError.length > 0
        @scrollToElement $firstValidationError

    # Get the global Dative application settings relevant to displaying
    # resources.
    # TODO: put these in the application settings model.
    getGlobalsResourcesDisplaySettings: ->
      defaults =
        itemsPerPage: 10
        dataLabelsVisible: true
        allResourcesExpanded: false
      try
        resourcesDisplaySettings = globals.applicationSettings.get(
          "#{@resourceNamePlural}DisplaySettings")
        _.extend defaults, resourcesDisplaySettings
      for key, value of defaults
        @[key] = value

    # Instantiate and return a new `ResourceView` instance. Note that even
    # though we pass the collection to the resource view's model, the
    # collection will not contain that model.
    getNewResourceView: (newResourceModel) ->
      newResourceModel = newResourceModel or
        new @resourceModel({}, collection: @collection)
      new @resourceView
        headerTitle: "New #{@resourceNameCapitalized}"
        model: newResourceModel
        dataLabelsVisible: @dataLabelsVisible
        expanded: @allResourcesExpanded

    getResourceSearchView: ->
      if @searchable
        searchModel = new @searchModel({}, collection: @collection)
        new @searchView
          headerTitle: "Search #{@resourceNamePluralCapitalized}"
          model: searchModel
          dataLabelsVisible: @dataLabelsVisible
          expanded: @allResourcesExpanded
      else
        null

    # This is called when the 'addResourceSuccess' has been triggered, i.e.,
    # when a new resource has been successfully created on the server.
    newResourceAdded: ->
      resourceModel = @newResourceView.model
      newResourceShouldBeOnCurrentPage = @newResourceShouldBeOnCurrentPage()
      # 1. Make the new resource widget disappear.
      @hideNewResourceViewAnimate()

      # 2. refresh the pagination stuff (necessarily changes)
      @paginator.setItems (@paginator.items + 1)

      @refreshHeader()
      @refreshPaginationMenuTop()

      # 3. If the new resource should be displayed on the current page, then
      # do that; otherwise notify the user that it's on the last page.
      Backbone.trigger "add#{@resourceNameCapitalized}Success", resourceModel
      if newResourceShouldBeOnCurrentPage
        @addNewResourceViewToPage()
        @closeNewResourceView()
      else
        @notifyNewResourceOnLastPage resourceModel
        @closeNewResourceView()

      # 4. create a new new resource widget but don't display it.
      # TODO: maybe the new new resource view *should* be displayed ...
      @newResourceViewVisible = false
      @newResourceView = @getNewResourceView()
      @renderNewResourceView()
      @newResourceViewVisibility()
      @listenToNewResourceView()

    notifyNewResourceOnLastPage: (resourceModel) ->
      Backbone.trigger 'newResourceOnLastPage', resourceModel, @resourceName

    destroyResourceSuccess: (resourceModel) ->
      @collection.remove resourceModel
      @paginator.setItems (@paginator.items - 1)
      @refreshHeader()
      @refreshPaginationMenuTop()
      destroyedResourceView = _.findWhere(@renderedResourceViews,
        {model: resourceModel})
      if destroyedResourceView
        destroyedResourceView.$el.slideUp()
      @fetchResourcesPageToCollection()

    # Returns true if a new resource should be on the currently displayed page.
    newResourceShouldBeOnCurrentPage: ->
      itemsDisplayedCount = (@paginator.end - @paginator.start) + 1
      if itemsDisplayedCount < @paginator.itemsPerPage then true else false

    # Add the new resource view to the set of paginated resource views.
    # This entails adding the new resource view's model to the collection
    # and then rendering it and adding it to the DOM.
    addNewResourceViewToPage: ->
      addedResourceView = new @resourceView
        model: @newResourceView.model
        dataLabelsVisible: @dataLabelsVisible
        expanded: @allResourcesExpanded
      @collection.add addedResourceView.model
      renderedView = @renderResourceView addedResourceView, @paginator.end
      @$('.dative-pagin-items').append renderedView.el

    # Keyboard shortcuts for the resources view.
    # Note that the ResourcesView is listening to events on parts of the DOM
    # that are more properly the domain of the Pagination Top Menu subview.
    keyboardShortcuts: (event) ->
      if not @addUpdateResourceWidgetHasFocus()
        if not event.ctrlKey and not event.metaKey and not event.altKey
          switch event.which
            when 70 then @$('.first-page').click() # f
            when 80 then @$('.previous-page').click() # p
            when 78 then @$('.next-page').click() # n
            when 76 then @$('.last-page').click() # l
            when 40 # down arrow
              if not @itemsPerPageSelectHasFocus()
                @$('.expand-all').click()
            when 38 # up arrow
              if not @itemsPerPageSelectHasFocus()
                @$('.collapse-all').click()
            when 65
              if @getCanCreateNew() then @toggleNewResourceViewAnimate() # a
            when 32 # spacebar goes to next resource view, shift+spacebar goes to previous.
              if event.shiftKey
                @focusPreviousResourceView event
              else
                @focusNextResourceView event

    # Return the (jQuery-wrapped) resource view <div> that encloses
    # `$element`, if it exists.
    getEnclosingResourceViewDiv: ($element) ->
      if $element.hasClass 'dative-resource-widget'
        $element
      else
        $resourceWidgetAncestors = $element.closest '.dative-resource-widget'
        if $resourceWidgetAncestors and $resourceWidgetAncestors.length > 0
          $resourceWidgetAncestors.first()
        else
          null

    getNextResourceViewDiv: ($enclosingResourceViewDiv) ->
      if @enumerateResources
        $nextResourceViewDiv = $enclosingResourceViewDiv
          .closest('.dative-pagin-item')
          .next()
          .find('.dative-resource-widget')
      else
        $nextResourceViewDiv = $enclosingResourceViewDiv.next()
      if $nextResourceViewDiv then $nextResourceViewDiv else null

    getPreviousResourceViewDiv: ($enclosingResourceViewDiv) ->
      if @enumerateResources
        $previousResourceViewDiv = $enclosingResourceViewDiv
          .closest('.dative-pagin-item')
          .prev()
          .find('.dative-resource-widget')
      else
        $previousResourceViewDiv = $enclosingResourceViewDiv.prev()
      if $previousResourceViewDiv then $previousResourceViewDiv else null

    # Focus the next (below) resource view, or the first one if we're at the
    # top.
    focusNextResourceView: (event) ->
      $enclosingResourceViewDiv = @getEnclosingResourceViewDiv(
        @$(event.target))
      if $enclosingResourceViewDiv
        $nextResourceViewDiv = @getNextResourceViewDiv $enclosingResourceViewDiv
        @stopEvent event
        if $nextResourceViewDiv.length
          $nextResourceViewDiv.focus()
        else
          @focusFirstResource()

    # Focus the previous (above) resource view, or the last one if we're at
    # the top.
    focusPreviousResourceView: (event) ->
      $enclosingResourceViewDiv = @getEnclosingResourceViewDiv(
        @$(event.target))
      if $enclosingResourceViewDiv.length
        $previousResourceViewDiv =
          @getPreviousResourceViewDiv $enclosingResourceViewDiv
        @stopEvent event
        if $previousResourceViewDiv.length
          $previousResourceViewDiv.focus()
        else
          @focusLastResource()

    # Returns true if the "items per page" selectmenu in the Pagination Top
    # Menu view has focus; we don't want the expand/collapse shortcuts to
    # be triggered when we're using the arrow keys to change the number of
    # resources being displayed.
    itemsPerPageSelectHasFocus: ->
      @$('.ui-selectmenu-button.items-per-page').is ':focus'

    resourceFocused: (event) ->
      if @$(event.target).hasClass 'dative-resource-widget'
        @rememberFocusedElement event
        $element = @$ event.target
        @scrollToScrollableElement $element

    inputFocused: (event) ->
      @stopEvent event
      @rememberFocusedElement event

    keyup: (event) ->
      if event.which is 9
        $element = @$ event.target
        @scrollToScrollableElement $element

    scrollToScrollableElement: ($element) ->
      if (not $element.hasClass('ui-selectmenu-button')) and
      (not $element.hasClass('ms-list')) and
      (not $element.hasClass('hasDatepicker'))
        @scrollToElement $element

    # Tell the Help dialog to open itself and search for "browsing resources"
    # and scroll to the second match. WARN: this is brittle because if the help
    # HTML changes, then the second match may not be what we want.
    openResourcesBrowseHelp: ->
      Backbone.trigger(
        'helpDialog:openTo',
        searchTerm: "browsing #{@utils.camel2regular @resourceNamePlural}"
        scrollToIndex: 1
      )

    # These are the focusable elements in the resources browse interface. See
    # BaseView for use of this attribute.
    focusableSelector: 'textarea, button, input, .ui-selectmenu-button,
      .dative-resource-widget'

    restoreFocusAndScrollPosition: ->
      @focusLastFocusedElement()
      @scrollToFocusedInput()

    # Toggle all primary data labels. Responds to `.toggle-all-labels` button.
    toggleAllLabels: ->
      if @dataLabelsVisible
        @hideAllLabels()
      else
        @showAllLabels()

    # Tell all rendered resources to show their primary data labels. (Also tell
    # all un-rendered resource views to show their labels when they do render.)
    showAllLabels: ->
      @dataLabelsVisible = true
      @setToggleAllLabelsButtonStateOpen()
      Backbone.trigger "#{@resourceNamePlural}View:showAllLabels"

    # Tell all rendered resources to hide their primary data labels. (Also tell
    # all un-rendered resource views to hide their labels when they do render.)
    hideAllLabels: ->
      @dataLabelsVisible = false
      @setToggleAllLabelsButtonStateClosed()
      Backbone.trigger "#{@resourceNamePlural}View:hideAllLabels"

    # Make the "toggle all labels button" match view state.
    setToggleAllLabelsButtonState: ->
      if @dataLabelsVisible
        @setToggleAllLabelsButtonStateOpen()
      else
        @setToggleAllLabelsButtonStateClosed()

    # Set "toggle all labels" button to state closed.
    setToggleAllLabelsButtonStateClosed: ->
      @$('.toggle-all-labels')
        .find 'i.fa'
          .removeClass 'fa-toggle-on'
          .addClass 'fa-toggle-off'
          .end()
        .button()
        .tooltip
          items: 'button'
          content: "#{@resourceNameHuman} labels are off; click here to turn
            them on"

    # Set "toggle all labels" button to state open.
    setToggleAllLabelsButtonStateOpen: ->
      @$('.toggle-all-labels')
        .find 'i.fa'
          .removeClass 'fa-toggle-off'
          .addClass 'fa-toggle-on'
          .end()
        .button()
        .tooltip
          items: 'button'
          content: "#{@resourceNameHuman} labels are on; click here to turn
            them off"

    # Tell all rendered resources to expand themselves; listen for one notice
    # of expansion from a resource view and respond by restoring the focus and
    # scroll position. (Also tell all un-rendered resource views to be expanded
    # when they do render.)
    expandAllResources: ->
      @allResourcesExpanded = true
      @listenToOnce Backbone, "resource:resourceExpanded",
        @restoreFocusAndScrollPosition
      Backbone.trigger "#{@resourceNamePlural}View:expandAll#{@resourceNamePluralCapitalized}"

    # Tell all rendered resources to collapse themselves; listen for one
    # notice of collapse from a resource view and respond by restoring the
    # focus and scroll position. (Also tell all un-rendered resource views to
    # be collapsed when they do render.)
    collapseAllResources: ->
      @allResourcesExpanded = false
      @focusEnclosingResourceView()
      @listenToOnce Backbone, "resource:resourceCollapsed",
        @restoreFocusAndScrollPosition
      Backbone.trigger "#{@resourceNamePlural}View:collapseAll#{@resourceNamePluralCapitalized}"

    # Sets focus to the ResourceView div that contains the focused control.
    # This is necessary so that we can restore scroll position after a
    # collapse-all request wherein a previously focused control will become
    # hidden and thus unfocusable.
    focusEnclosingResourceView: ->
      $focusedElement = @$ ':focus'
      if $focusedElement
        $focusedElement.closest('.dative-resource-widget').first().focus()

    # Get a page of resources from a web service. Note that the resources
    # collection only holds one page at a time; that is, the collection is
    # emptied and refilled on each pagination action, hence the `.reset()` call
    # here.
    fetchResourcesPageToCollection: ->
      @collection.reset()
      @collection.fetchResources @paginator

    # Render the pagination top menu view. This is the row of buttons for
    # controlling the visible pagination page and how many items are visible
    # per page.
    renderPaginationMenuTopView: ->
      @paginationMenuTopView.setElement(
        @$('div.dative-pagination-menu-top').first())
      @paginationMenuTopView.render paginator: @paginator
      @rendered @paginationMenuTopView

    # Render the New Resource view.
    renderNewResourceView: ->
      if @getCanCreateNew()
        @newResourceView.setElement @$('.new-resource-view').first()
        @newResourceView.render()
        @rendered @newResourceView

    # Close the New Resource view.
    closeNewResourceView: ->
      @newResourceView.close()
      @closed @newResourceView

    ############################################################################
    # Respond to `@collection`-issued events related to the "fetch resources"
    # task.
    ############################################################################

    fetchResourcesStart: ->
      @fetchCompleted = false
      @spin()

    fetchResourcesEnd: ->
      @fetchCompleted = true

    fetchResourcesFail: (reason) ->
      @stopSpin()
      console.log 'fetchResourcesFail'
      console.log reason
      @$('.no-resources')
        .show()
        .text reason

    # We have succeeded in retrieving a page of resources from a server.
    # `paginator` is an object returned from the server. Crucially, it has an
    # attribute `count` which tells us how many resources are in the database.
    fetchResourcesSuccess: (paginator) ->
      @saveFetchedMetadata()
      @getResourceViews()
      if paginator then @paginator.setItems paginator.count
      if @paginator.items is 0 then @fetchResourcesLastPage = false
      if @fetchResourcesLastPage
        pageBefore = @paginator.page
        @paginator.setPageToLast()
        pageAfter = @paginator.page
        if pageBefore isnt pageAfter
          @fetchResourcesLastPage = false
          @fetchResourcesPageToCollection()
        else
          @refreshPageFade()
      else
        @refreshPageFade()

    # Tell the paginator how many items/resources are in our corpus/database.

    # Remember the server type and name (and corpus name) of the last resources
    # fetch, so we don't needlessly repeat it on future renderings of this
    # entire ResourcesView. The `@lastFetched` object that is updated here is
    # only accessed by `@weNeedToFetchResourcesAgain()` when `@render()` is
    # called.
    saveFetchedMetadata: ->
      @lastFetched.serverName = @getActiveServerName()

    getActiveServerType: ->
      globals.applicationSettings.get('activeServer').get 'type'

    getActiveServerName: ->
      globals.applicationSettings.get('activeServer').get 'name'

    getActiveServerFieldDBCorpusPouchname: ->
      if @getActiveServerType() is 'FieldDB'
        globals.applicationSettings.get 'activeFieldDBCorpus'
      else
        null

    # Returns false if we have already fetched these resources; prevents redundant
    # requests.
    weNeedToFetchResourcesAgain: ->
      if @searchChanged
        @searchChanged = false
        true
      else
        toFetch = serverName: @getActiveServerName()
        if _.isEqual(toFetch, @lastFetched) then false else true

    # Refresh the page to reflect the current state. This means refreshing the
    # top menu header of the resources browse page, the pagination sub-header
    # and the list of resources displayed.
    refreshPage: (options) ->
      @refreshHeader()
      @refreshPaginationMenuTop()
      @closeThenOpenCurrentPage options

    # Refresh the page using fade out/in as the animations.
    refreshPageFade: ->
      @refreshPage
        hideEffect: 'fadeOut'
        showEffect: 'fadeIn'

    # Refresh the content of the resources browse header.
    # This is the top "row" of the header, with the "create a new resource"
    # button, the "expand/collapse all" buttons and the title.
    # (Note that the pagination controls are handled by the PaginationMenuTopView.)
    refreshHeader: ->
      if not @fetchCompleted
        @disableHeader()
        return
      if @paginator.items is 0
        @headerForEmptyDataSet()
      else
        @headerForContentfulDataSet()

    # Disable all buttons on the header and tell the user that we're working on
    # fething data from the server.
    disableHeader: ->
      @$('.no-resources')
        .show()
        .text 'Fetching data from the server ...'
      @$('.pagination-info').hide()
      @$('button.expand-all').button 'disable'
      @$('button.collapse-all').button 'disable'
      @$('button.new-resource').button 'disable'
      @$('button.toggle-all-labels').button 'disable'

    # Configure the header appropriately for the case where there are no
    # resources to browse.
    headerForEmptyDataSet: ->
      @$('.no-resources')
        .show()
        .text "There are no #{@resourceNamePlural} to display"
      @$('.pagination-info').hide()
      @$('button.expand-all').button 'disable'
      @$('button.collapse-all').button 'disable'
      @$('button.toggle-all-labels').button 'disable'
      @setToggleAllLabelsButtonState()
      @setNewResourceViewButtonState()

    # Configure the header appropriately for the case where we have a page
    # that *has* some resources in it.
    headerForContentfulDataSet: ->
      @$('.no-resources').hide()
      @$('.pagination-info').show()
      @$('button.expand-all').button 'enable'
      @$('button.collapse-all').button 'enable'
      @$('button.toggle-all-labels').button 'enable'
      @setToggleAllLabelsButtonState()
      @setNewResourceViewButtonState()
      if @search
        @$('.browse-set').text "a search over
          #{@resourceNamePluralHuman}"
      else if @corpus
        @$('.browse-set').html "<a
          href='javascript:;'
          class='field-display-link dative-tooltip corpus-display'
          title='click here to view this corpus in this page'
          >corpus #{@corpus.get('id')}</a>"
      else
        @$('.browse-set').text "all #{@resourceNamePluralHuman}"
      if @paginator.start is @paginator.end
        @$('.resource-range')
          .text("#{@utils.camel2regular @resourceName}
            #{@utils.integerWithCommas(@paginator.start + 1)}")
      else
        @$('.resource-range').text("#{@utils.camel2regular @resourceNamePluralHuman}
          #{@utils.integerWithCommas(@paginator.start + 1)}
          to
          #{@utils.integerWithCommas(@paginator.end + 1)}")
      @$('.resource-count').text @utils.integerWithCommas(@paginator.items)
      @$('.resource-count-noun').text(
        @utils.pluralizeByNum(@resourceName, @paginator.items))
      @$('.current-page').text @utils.integerWithCommas(@paginator.page)
      @$('.page-count').text @utils.integerWithCommas(@paginator.pages)

    # Tell the pagination menu top view to re-render itself given the current
    # state of the paginator.
    refreshPaginationMenuTop: ->
      @paginationMenuTopView.render paginator: @paginator

    # Hide the current page of resources and provide a `complete` callback which
    # will re-open/draw the page with the new resources, by calling `@renderPage`.
    closeThenOpenCurrentPage: (options) ->
      hideMethod = 'hide'
      hideOptions =
        complete: =>
          @$('.dative-pagin-items').html ''
          @closeRenderedResourceViews()
          if @enumerateResources then @closePaginationItemTableViews()
          @renderPage options
      if options?.hideEffect
        hideOptions.duration = @getAnimationDuration()
        hideMethod = options.hideEffect
      @$('.dative-pagin-items')[hideMethod] hideOptions

    getAnimationDuration: ->
      100 # Better to be fast than try to do something fancy like below...
      # 100 + (10 * @paginator.itemsDisplayed)

    # Close all rendered resource views: remove them from the DOM, but also prevent
    # them from reacting to events.
    closeRenderedResourceViews: ->
      while @renderedResourceViews.length
        resourceView = @renderedResourceViews.pop()
        resourceView.close()
        @closed resourceView

    closeResourceViews: ->
      while @resourceViews.length
        resourceView = @resourceViews.pop()
        resourceView.close()
        @closed resourceView

    # Close all rendered pagination item table views, i.e., the mini-tables that
    # hold enumerated resource views.
    closePaginationItemTableViews: ->
      while @paginationItemTableViews.length
        paginationItemTableView = @paginationItemTableViews.pop()
        paginationItemTableView.close()
        @closed paginationItemTableView

    # Create a `ResourceView` instance for each `ResourceModel` instance in
    # `@collection` and append it to `@resourceViews`.
    # Note that we reset `resourceViews` to `[]` because with server-side
    # pagination we only store one page worth of resource models/views at a
    # time.
    getResourceViews: ->
      @closeResourceViews()
      @resourceViews = []
      @collection.each (resourceModel) =>
        newResourceView = new @resourceView
          model: resourceModel
          dataLabelsVisible: @dataLabelsVisible
          expanded: @allResourcesExpanded
        @resourceViews.push newResourceView

    spinnerOptions: ->
      # _.extend BaseView::spinnerOptions(), {top: '25%', left: '85.5%'}
      _.extend BaseView::spinnerOptions(), {top: '50%', left: '-10%'}

    spin: ->
      # @$('#dative-page-header').spin @spinnerOptions()
      @$('.spinner-anchor').first().spin @spinnerOptions()

    stopSpin: ->
      # @$('#dative-page-header').spin false
      @$('.spinner-anchor').first().spin false

    setFocus: ->
      if @focusedElementIndex?
        @weShouldFocusFirstAddViewInput = false
        @focusLastFocusedElement()
      else if @weShouldFocusFirstAddViewInput
        @focusFirstNewResourceViewTextarea()
      else
        @focusLastResource()
      @scrollToFocusedInput()

    focusFirstButton: ->
      @$('button.ui-button').first().focus()

    focusFirstResource: ->
      @$('div.dative-resource-widget').first().focus()

    focusLastResource: ->
      if @renderedResourceViews.length > 0
        @renderedResourceViews[@renderedResourceViews.length - 1].$el.focus()

    focusFirstNewResourceViewTextarea: ->
      @$('.new-resource-view .add-resource-widget textarea').first().focus()

    # GUI-fy: make nice buttons and nice titles/tooltips
    guify: ->
      @$('button').button().attr('tabindex', 0)
      @$('button.new-resource')
        .button()
        .tooltip
          position:
            my: "right-10 center"
            at: "left center"
            collision: "flipfit"
      @$('button.expand-all')
        .button()
        .tooltip
          position:
            my: "right-45 center"
            at: "left center"
            collision: "flipfit"
      @$('button.collapse-all')
        .button()
        .tooltip
          position:
            my: "right-80 center"
            at: "left center"
            collision: "flipfit"
      @$('button.resources-browse-help')
        .button()
        .tooltip
          position:
            my: "left+10 center"
            at: "right center"
            collision: "flipfit"
      @$('button.toggle-search')
        .button()
        .tooltip
          position:
            my: "left+130 center"
            at: "right center"
            collision: "flipfit"
      @$('button.toggle-all-labels')
        .button()
        .tooltip
          position:
            my: "left+45 center"
            at: "right center"
            collision: "flipfit"
      # @$('.browse-set')
      # .css 'color': @constructor.jQueryUIColors().hovCo

    # Render a page (pagination) of resource views. That is, change which set of
    # `ResourceView` instances are displayed.
    renderPage: (options) ->
      # @paginator._refresh() # This seems to be unnecessary.
      @renderResourceViews()
      @stopSpin()
      @showResourceList options

    # Render all resource views on the current paginator page.
    # Note that each pagination change event triggers a new fetch to the
    # server, and a resetting of both `@collection` and `@resourceViews`; thus
    # we render all resource models in the collection (and all resource views
    # in `@resourceViews`) using the "indices" from `@paginator`.
    renderResourceViews: ->
      paginationIndices = [@paginator.start..@paginator.end]
      fragment = document.createDocumentFragment()
      for [index, resourceView] in _.zip(paginationIndices, @resourceViews)
        renderedView = @renderResourceView resourceView, index
        if renderedView then fragment.appendChild renderedView.el
      @$('.dative-pagin-items').append fragment

    # Render a single resource view, but don't add it to the DOM: just return
    # it.
    renderResourceView: (resourceView, index) ->
      if resourceView # resourceView may be undefined.
        if @enumerateResources # i.e., add example numbers, e.g.,  "(1)"
          resourceId = resourceView.model.get 'id'
          viewToReturn = new PaginationItemTableView
            resourceId: resourceId
            index: index + 1
          viewToReturn.render()
          viewToReturn.$("##{resourceId}").html resourceView.render().el
          @paginationItemTableViews.push viewToReturn
          @rendered viewToReturn
        else
          viewToReturn = resourceView.render()
        @renderedResourceViews.push resourceView
        @rendered resourceView
        viewToReturn

    # jQuery-show the list of resources.
    showResourceList: (options) ->
      $resourceList = @$ '.dative-pagin-items'
      if options?.showEffect
        $resourceList[options.showEffect]
          duration: @getAnimationDuration()
          complete: =>
            @setFocus()
      else
        $resourceList.show()
        @setFocus()


    ############################################################################
    # Respond to requests from the Pagination Menu Top View
    ############################################################################

    changeItemsPerPage: (newItemsPerPage) ->
      # TODO: have the App view listen for this event and persist these
      # application settings, as it does with forms.
      Backbone.trigger "#{@resourceNamePlural}View:itemsPerPageChange",
        newItemsPerPage
      @itemsPerPage = newItemsPerPage
      itemsDisplayedBefore = @paginator.itemsDisplayed
      @paginator.setItemsPerPage newItemsPerPage
      itemsDisplayedAfter = @paginator.itemsDisplayed
      if itemsDisplayedBefore isnt itemsDisplayedAfter
        @fetchResourcesPageToCollection()

    showFirstPage: ->
      pageBefore = @paginator.page
      @paginator.setPageToFirst()
      pageAfter = @paginator.page
      if pageBefore isnt pageAfter
        @fetchResourcesPageToCollection()

    showPreviousPage: ->
      pageBefore = @paginator.page
      @paginator.setPageToPrevious()
      pageAfter = @paginator.page
      if pageBefore isnt pageAfter
        @fetchResourcesPageToCollection()

    showNextPage: ->
      pageBefore = @paginator.page
      @paginator.setPageToNext()
      pageAfter = @paginator.page
      if pageBefore isnt pageAfter
        @fetchResourcesPageToCollection()

    showLastPage: ->
      pageBefore = @paginator.page
      @paginator.setPageToLast()
      pageAfter = @paginator.page
      if pageBefore isnt pageAfter
        @fetchResourcesPageToCollection()

    # Show a new page where `method` determines whether the new page is
    # behind or ahead of the current one and where `n` is the number of
    # pages behind or ahead.
    showPage: (n, method) ->
      pageBefore = @paginator.page
      @paginator[method] n
      pageAfter = @paginator.page
      if pageBefore isnt pageAfter
        @fetchResourcesPageToCollection()

    showThreePagesBack: ->
      @showPage 3, 'decrementPage'

    showTwoPagesBack: ->
      @showPage 2, 'decrementPage'

    showOnePageBack: ->
      @showPage 1, 'decrementPage'

    showOnePageForward: ->
      @showPage 1, 'incrementPage'

    showTwoPagesForward: ->
      @showPage 2, 'incrementPage'

    showThreePagesForward: ->
      @showPage 3, 'incrementPage'

    ############################################################################
    # Show, hide and toggle the Resource Add widget view
    ############################################################################

    # Make the ResourceAddWidgetView visible or not, depending on its last
    # state.
    newResourceViewVisibility: ->
      if @newResourceViewVisible
        @showNewResourceView()
      else
        @hideNewResourceView()

    hideNewResourceView: ->
      @setNewResourceViewButtonShow()
      @newResourceViewVisible = false
      @$('.new-resource-view').hide()

    showNewResourceView: ->
      @setNewResourceViewButtonHide()
      @newResourceViewVisible = true
      @$('.new-resource-view').show
        complete: =>
          @newResourceView.showUpdateView()
          Backbone.trigger "add#{@resourceNameCapitalized}WidgetVisible"

    hideNewResourceViewAnimate: ->
      @setNewResourceViewButtonShow()
      @newResourceViewVisible = false
      @$('.new-resource-view').slideUp()
      @newResourceView.closeAllTooltips()
      @focusLastResource()
      @scrollToFocusedInput()

    showNewResourceViewAnimate: ->
      @setNewResourceViewButtonHide()
      @newResourceViewVisible = true
      @$('.new-resource-view').slideDown
        complete: =>
          @newResourceView.showUpdateViewAnimate()
          Backbone.trigger "add#{@resourceNameCapitalized}WidgetVisible"
      @focusFirstNewResourceViewTextarea()
      @scrollToFocusedInput()

    toggleNewResourceViewAnimate: ->
      if @$('.new-resource-view').is ':visible'
        @hideNewResourceViewAnimate()
      else
        @showNewResourceViewAnimate()

    setNewResourceViewButtonState: ->
      if @newResourceViewVisible
        @setNewResourceViewButtonHide()
      else
        @setNewResourceViewButtonShow()

    setNewResourceViewButtonShow: ->
      @$('button.new-resource')
        .button 'enable'
        .tooltip
          content: "create a new #{@resourceNameHuman}"

    # The resource add view show "+" button is disabled when the view is visible; to
    # hide the view, you click on the ^ button on the view itself.
    setNewResourceViewButtonHide: ->
      @$('button.new-resource')
        .button 'disable'

    # Duplicate the supplied resource model, but display a confirm dialog first if the
    # new resource view has data in it.
    duplicateResourceConfirm: (resourceModel) ->
      if @newResourceView.model.isEmpty()
        @duplicateResource resourceModel
      else
        id = resourceModel.get 'id'
        options =
          text: "The “new #{@resourceName}” #{@resourceName} has unsaved
            data in it. If you proceed with duplicating #{@resourceName} #{id},
            you will lose that unsaved information. Click “Cancel” to abort the
            duplication so you can save your unsaved new #{@resourceName}
            first. If you are okay with discarding your unsaved new
            #{@resourceName}, then click “Ok” to proceed with duplicating
            #{@resourceName} #{id}."
          confirm: true
          confirmEvent: "duplicate#{@resourceNameCapitalized}"
          confirmArgument: resourceModel
        Backbone.trigger 'openAlertDialog', options

    # Duplicate a resource model and display it for editing in the "New Resource"
    # widget.
    duplicateResource: (resourceModel) ->
      newResourceModel = resourceModel.clone()

      # We don't want to duplicate the server-generated attributes of the
      # resource.
      editableAttributes = resourceModel.editableAttributes
      defaults = @resourceModel::defaults()
      for attribute in editableAttributes
        delete defaults[attribute]
      newResourceModel.set defaults
      newResourceModel.collection = @collection

      # TODO: if the current New Resource view has a non-empty model we should
      # either warn the user about that or we should intelligently store that
      # model for later ...

      @hideNewResourceViewAnimate()
      @closeNewResourceView()
      @newResourceView = @getNewResourceView newResourceModel
      @renderNewResourceView()
      @listenToNewResourceView()
      @showNewResourceViewAnimate()

    openExporterDialog: (options) ->
      @exporterDialog.setToBeExported options
      @exporterDialog.generateExport()
      @exporterDialog.dialogOpen()


    # Search-relevant stuff
    ############################################################################

    # Set `@searchable` to `true` if this resource can be searched.
    searchable: false

    # Override this to return `false` in those cases where a user should not be
    # able to create a new resource.
    getCanCreateNew: -> true

    # If this resource is searchable, then set `@searchView` and `@searchModel`
    # to a view and a model class, respectively, for creating new searches for
    # this resource.
    searchView: null
    searchModel: null

    # By default, we have no search object. If this is set, it is assumed to be
    # an object of the form `{query: {filter: [], order_by: []}}`.
    search: null

    # Setting this to `true` will cause `@weNeedToFetchResourcesAgain()` to
    # return `true`.
    searchChanged: false

    # Give this resources view a (new) search object. This will affect what
    # forms we are browsing.
    setSearch: (@search) ->
      @searchChanged = true
      @paginator = new Paginator page=1, items=0, itemsPerPage=@itemsPerPage
      @collection.search = @search

    # Delete this resource view's a search object. This will also affect what
    # forms we are browsing.
    deleteSearch: ->
      @searchChanged = true
      @search = null
      @collection.search = null
      @paginator = new Paginator page=1, items=0, itemsPerPage=@itemsPerPage


    # Corpus-relevant stuff -- NOTE: only relevant for collections of forms.
    ############################################################################

    # By default, we have no corpus model.
    corpus: null

    # Setting this to `true` will cause `@weNeedToFetchResourcesAgain()` to
    # return `true`.
    corpusChanged: false

    # Give this resources view a (new) corpus model. This will affect what
    # forms we are browsing.
    setCorpus: (@corpus) ->
      @corpusChanged = true
      @paginator = new Paginator page=1, items=0, itemsPerPage=@itemsPerPage
      # TODO: make collection sensitive to the corpus attr.
      @collection.corpus = @corpus

    # Delete this resource view's corpus model. This will also affect what
    # forms we are browsing.
    deleteCorpus: ->
      @corpusChanged = true
      @corpus = null
      @collection.corpus = null
      @paginator = new Paginator page=1, items=0, itemsPerPage=@itemsPerPage


    ############################################################################
    # Show, hide and toggle the resource search widget view
    ############################################################################

    # Make the ResourceSearchView visible or not, depending on its last
    # state.
    resourceSearchViewVisibility: ->
      if @resourceSearchViewVisible
        @showResourceSearchView()
      else
        @hideResourceSearchView()

    hideResourceSearchView: ->
      @setResourceSearchViewButtonShow()
      @resourceSearchViewVisible = false
      @$('.resource-search-view').hide()

    showResourceSearchView: ->
      if not @resourceSearchViewRendered
        @renderResourceSearchView()
      @setResourceSearchViewButtonHide()
      @resourceSearchViewVisible = true
      @$('.resource-search-view').show()

    hideResourceSearchViewAnimate: ->
      @setResourceSearchViewButtonShow()
      @resourceSearchViewVisible = false
      @$('.resource-search-view').slideUp
        complete: =>
          @resourceSearchView.closeAllTooltips()
          @focusLastResource()
          @scrollToFocusedInput()

    showResourceSearchViewAnimate: ->
      if not @resourceSearchViewRendered
        @renderResourceSearchView()
      @setResourceSearchViewButtonHide()
      @resourceSearchViewVisible = true
      @$('.resource-search-view').slideDown
        complete: =>
          @focusFirstResourceSearchViewTextarea()
          @scrollToFocusedInput()

    focusFirstResourceSearchViewTextarea: ->
      @$('.resource-search-view textarea').first().focus()

    toggleResourceSearchViewAnimate: ->
      if @$('.resource-search-view').is ':visible'
        @hideResourceSearchViewAnimate()
      else
        @showResourceSearchViewAnimate()

    setResourceSearchViewButtonState: ->
      if @resourceSearchViewVisible
        @setResourceSearchViewButtonHide()
      else
        @setResourceSearchViewButtonShow()

    setResourceSearchViewButtonShow: ->
      @$('button.toggle-search')
        .tooltip
          content: "click here to open the interface for searching across
            #{@resourceNamePluralHuman}"

    # The resource add view show "+" button is disabled when the view is visible; to
    # hide the view, you click on the ^ button on the view itself.
    setResourceSearchViewButtonHide: ->
      @$('button.toggle-search')
        .tooltip
          content: "click here to hide the interface for searching across
            #{@resourceNamePluralHuman}"

    # Render the Resource Search view.
    renderResourceSearchView: ->
      if @searchable
        @resourceSearchView.setElement @$('.resource-search-view').first()
        @resourceSearchView.render()
        @rendered @resourceSearchView
        @resourceSearchViewRendered = true

