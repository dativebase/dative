define [
  './base'
  './subcorpus'
  './exporter-dialog'
  './pagination-menu-top'
  './../collections/subcorpora'
  './../models/subcorpus'
  './../utils/paginator'
  './../utils/globals'
  './../templates/subcorpora'
], (BaseView, SubcorpusView, ExporterDialogView, PaginationMenuTopView,
  SubcorporaCollection, SubcorpusModel, Paginator, globals,
  subcorporaTemplate) ->

  # Subcorpora View
  # ---------------
  #
  # Displays a list of subcorpora (i.e., OLD corpora) for browsing (with
  # pagination).
  #
  # Also contains a model-less SubcorpusView instance for creating new
  # subcorpora within the subcorpora browse interface.

  class SubcorporaView extends BaseView

    template: subcorporaTemplate

    initialize: (options) ->
      @getGlobalsSubcorporaDisplaySettings()
      @focusedElementIndex = null
      @subcorpusViews = [] # holds a SubcorpusView instance for each SubcorpusModel in SubcorporaCollection
      @renderedSubcorpusViews = [] # references to the SubcorpusView instances that are rendered
      @weShouldFocusFirstAddViewInput = false # AppView sets this to True when you click Subcorpora > Add
      @fetchCompleted = false
      @fetchSubcorporaLastPage = false # This is set to true when we want to fetch the last page immediately after fetching the first one.
      @lastFetched = # We store this to help us prevent redundant requests to the server for all subcorpora.
        serverName: ''
      @paginator = new Paginator page=1, items=0, itemsPerPage=@itemsPerPage
      @paginationMenuTopView = new PaginationMenuTopView paginator: @paginator # This handles the UI for the items-per-page select, the first, prevous, next buttons, etc.
      @collection = new SubcorporaCollection()
      @newSubcorpusview = @getNewSubcorpusView()
      @exporterDialog = new ExporterDialogView()
      @newSubcorpusViewVisible = false
      @listenToEvents()

    events:
      'focus input, textarea, .ui-selectmenu-button, button, .ms-container': 'inputFocused'
      'focus .dative-subcorpus-widget': 'subcorpusFocused'
      'click .expand-all': 'expandAllSubcorpora'
      'click .collapse-all': 'collapseAllSubcorpora'
      'click .new-subcorpus': 'showNewSubcorpusViewAnimate'
      'click .subcorpora-browse-help': 'openSubcorporaBrowseHelp'
      'click .toggle-all-labels': 'toggleAllLabels'
      'keydown': 'keyboardShortcuts'
      'keyup': 'keyup'
      # @$el is enclosed in top and bottom invisible divs. These allow us to
      # close-circuit the tab loop and keep focus in the view.
      'focus .focusable-top':  'focusLastElement'
      'focus .focusable-bottom':  'focusFirstElement'

    render: (taskId) ->
      @html()
      @matchHeights()
      @guify()
      @refreshHeader()
      @renderPaginationMenuTopView()
      @renderNewSubcorpusView()
      @renderExporterDialogView()
      @newSubcorpusViewVisibility()
      if @weNeedToFetchSubcorporaAgain()
        @fetchSubcorporaToCollection()
      else
        @refreshPage()
      @listenToEvents()
      @setFocus()
      Backbone.trigger 'longTask:deregister', taskId
      @

    renderExporterDialogView: ->
      @exporterDialog.setElement(@$('#exporter-dialog-container'))
      @exporterDialog.render()
      @rendered @exporterDialog

    html: ->
      @$el.html @template
        pluralizeByNum: @utils.pluralizeByNum
        paginator: @paginator

    listenToEvents: ->
      super

      @listenTo Backbone, 'fetchSubcorporaStart', @fetchSubcorporaStart
      @listenTo Backbone, 'fetchSubcorporaEnd', @fetchSubcorporaEnd
      @listenTo Backbone, 'fetchSubcorporaFail', @fetchSubcorporaFail
      @listenTo Backbone, 'fetchSubcorporaSuccess', @fetchSubcorporaSuccess

      @listenTo Backbone, 'destroySubcorpusSuccess', @destroySubcorpusSuccess
      @listenTo Backbone, 'duplicateSubcorpus', @duplicateSubcorpus
      @listenTo Backbone, 'duplicateSubcorpusConfirm',
        @duplicateSubcorpusConfirm

      @listenTo Backbone, 'updateSubcorpusFail', @scrollToFirstValidationError
      @listenTo Backbone, 'addSubcorpusFail', @scrollToFirstValidationError

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

      @listenToNewSubcorpusView()

    listenToNewSubcorpusView: ->
      @listenTo @newSubcorpusview, 'newSubcorpusView:hide',
        @hideNewSubcorpusViewAnimate
      @listenTo @newSubcorpusview.model, 'addSubcorpusSuccess',
        @newSubcorpusAdded

    # TODO: fix this!
    scrollToFirstValidationError: (error, subcorpusModel) ->
      if subcorpusModel.id
        # TODO: this won't work because we don't have pagination tables with
        # .cid ids in them for subcorpora...
        selector = "##{subcorpusModel.cid} .dative-field-validation-container"
      else
        selector = ".new-subcorpus-view .dative-field-validation-container"
      $firstValidationError = @$(selector).filter(':visible').first()
      if $firstValidationError then @scrollToElement $firstValidationError

    # Get the global Dative application settings relevant to displaying
    # subcorpora.
    # TODO: put these in the application settings model.
    getGlobalsSubcorporaDisplaySettings: ->
      defaults =
        itemsPerPage: 10
        primaryDataLabelsVisible: true
        allSubcorporaExpanded: false
      try
        subcorporaDisplaySettings = globals.applicationSettings.get(
          'subcorporaDisplaySettings')
        _.extend defaults, subcorporaDisplaySettings
      for key, value of defaults
        @[key] = value

    # Instantiate and return a new `SubcorpusView` instance. Note that even
    # though we pass the collection to the subcorpus view's model, the
    # collection will not contain that model.
    getNewSubcorpusView: (newSubcorpusModel) ->
      newSubcorpusModel = newSubcorpusModel or new SubcorpusModel(collection: @collection)
      new SubcorpusView
        headerTitle: 'New Subcorpus'
        model: newSubcorpusModel
        primaryDataLabelsVisible: @primaryDataLabelsVisible
        expanded: @allSubcorporaExpanded

    # This is called when the 'addSubcorpusSuccess' has been triggered, i.e.,
    # when a new subcorpus has been successfully created on the server.
    newSubcorpusAdded: (subcorpusModel) ->
      newSubcorpusShouldBeOnCurrentPage = @newSubcorpusShouldBeOnCurrentPage()
      # 1. Make the new subcorpus widget disappear.
      @hideNewSubcorpusViewAnimate()

      # 2. refresh the pagination stuff (necessarily changes)
      @paginator.setItems (@paginator.items + 1)
      @refreshHeader()
      @refreshPaginationMenuTop()

      # 3. If the new subcorpus should be displayed on the current page, then
      # do that.
      Backbone.trigger 'addSubcorpusSuccess', subcorpusModel
      if newSubcorpusShouldBeOnCurrentPage
        @addNewSubcorpusViewToPage()
      else
        @closeNewSubcorpusView()

      # 4. create a new new subcorpus widget but don't display it.
      # TODO: maybe the new new subcorpus view *should* be displayed ...
      @newSubcorpusViewVisible = false
      @newSubcorpusview = @getNewSubcorpusView()
      @renderNewSubcorpusView()
      @newSubcorpusViewVisibility()
      @listenToNewSubcorpusView()

    destroySubcorpusSuccess: (subcorpusModel) ->
      @paginator.setItems (@paginator.items - 1)
      @refreshHeader()
      @refreshPaginationMenuTop()
      destroyedSubcorpusView = _.findWhere(@renderedSubcorpusViews,
        {model: subcorpusModel})
      if destroyedSubcorpusView
        destroyedSubcorpusView.$el.slideUp()
      @fetchSubcorporaPageToCollection()

    # Returns true if a new subcorpus should be on the currently displayed page.
    newSubcorpusShouldBeOnCurrentPage: ->
      itemsDisplayedCount = (@paginator.end - @paginator.start) + 1
      if itemsDisplayedCount < @paginator.itemsPerPage then true else false

    # Add the new subcorpus view to the set of paginated subcorpus views.
    # This entails adding the new subcorpus view's model to the collection
    # and then rendering it and adding it to the DOM.
    addNewSubcorpusViewToPage: ->
      addedSubcorpusView = new SubcorpusView
        model: @newSubcorpusview.model
        primaryDataLabelsVisible: @primaryDataLabelsVisible
        expanded: @allSubcorporaExpanded
      @collection.add addedSubcorpusView.model
      @renderSubcorpusView addedSubcorpusView, @paginator.end

    # Keyboard shortcuts for the subcorpora view.
    # Note that the SubcorporaView is listening to events on parts of the DOM
    # that are more properly the domain of the Pagination Top Menu subview.
    keyboardShortcuts: (event) ->
      if not @addUpdateSubcorpusWidgetHasFocus()
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
            when 65 then @toggleNewSubcorpusViewAnimate() # a
            when 32 # spacebar goes to next subcorpus view, shift+spacebar goes to previous.
              if event.shiftKey
                @focusPreviousSubcorpusView event
              else
                @focusNextSubcorpusView event

    # Return the (jQuery-wrapped) subcorpus view <div> that encloses
    # `$element`, if it exists.
    getEnclosingSubcorpusViewDiv: ($element) ->
      if $element.hasClass 'dative-subcorpus-widget'
        $element
      else
        $subcorpusWidgetAncestors = $element.closest '.dative-subcorpus-widget'
        if $subcorpusWidgetAncestors and $subcorpusWidgetAncestors.length > 0
          $subcorpusWidgetAncestors.first()
        else
          null

    # Focus the next (below) subcorpus view, or the first one if we're at the
    # top.
    focusNextSubcorpusView: (event) ->
      $enclosingSubcorpusViewDiv = @getEnclosingSubcorpusViewDiv(
        @$(event.target))
      if $enclosingSubcorpusViewDiv
        $nextSubcorpusViewDiv = $enclosingSubcorpusViewDiv.next()
        @stopEvent event
        if $nextSubcorpusViewDiv.length
          $nextSubcorpusViewDiv.focus()
        else
          @focusFirstSubcorpus()

    # Focus the previous (above) subcorpus view, or the last one if we're at
    # the top.
    focusPreviousSubcorpusView: (event) ->
      $enclosingSubcorpusViewDiv = @getEnclosingSubcorpusViewDiv(
        @$(event.target))
      if $enclosingSubcorpusViewDiv.length
        $previousSubcorpusViewDiv = $enclosingSubcorpusViewDiv.prev()
        @stopEvent event
        if $previousSubcorpusViewDiv.length
          $previousSubcorpusViewDiv.focus()
        else
          @focusLastSubcorpus()

    # Returns true if the "items per page" selectmenu in the Pagination Top
    # Menu view has focus; we don't want the expand/collapse shortcuts to
    # be triggered when we're using the arrow keys to change the number of
    # subcorpora being displayed.
    itemsPerPageSelectHasFocus: ->
      @$('.ui-selectmenu-button.items-per-page').is ':focus'

    subcorpusFocused: (event) ->
      if @$(event.target).hasClass 'dative-subcorpus-widget'
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

    # Tell the Help dialog to open itself and search for "browsing subcorpora"
    # and scroll to the second match. WARN: this is brittle because if the help
    # HTML changes, then the second match may not be what we want.
    openSubcorporaBrowseHelp: ->
      Backbone.trigger(
        'helpDialog:openTo',
        searchTerm: 'browsing subcorpora'
        scrollToIndex: 1
      )

    # These are the focusable elements in the subcorpora browse interface. See
    # BaseView for use of this attribute.
    focusableSelector: 'textarea, button, input, .ui-selectmenu-button,
      .dative-subcorpus-widget'

    restoreFocusAndScrollPosition: ->
      @focusLastFocusedElement()
      @scrollToFocusedInput()

    # Toggle all primary data labels. Responds to `.toggle-all-labels` button.
    toggleAllLabels: ->
      if @primaryDataLabelsVisible
        @hideAllLabels()
      else
        @showAllLabels()

    # Tell all rendered subcorpora to show their primary data labels. (Also tell
    # all un-rendered subcorpus views to show their labels when they do render.)
    showAllLabels: ->
      @primaryDataLabelsVisible = true
      @setToggleAllLabelsButtonStateOpen()
      Backbone.trigger 'subcorporaView:showAllLabels'

    # Tell all rendered subcorpora to hide their primary data labels. (Also tell
    # all un-rendered subcorpus views to hide their labels when they do render.)
    hideAllLabels: ->
      @primaryDataLabelsVisible = false
      @setToggleAllLabelsButtonStateClosed()
      Backbone.trigger 'subcorporaView:hideAllLabels'

    # Make the "toggle all labels button" match view state.
    setToggleAllLabelsButtonState: ->
      if @primaryDataLabelsVisible
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
          content: 'subcorpus labels are off; click here to turn them on'

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
          content: 'subcorpus labels are on; click here to turn them off'

    # Tell all rendered subcorpora to expand themselves; listen for one notice
    # of expansion from a subcorpus view and respond by restoring the focus and
    # scroll position. (Also tell all un-rendered subcorpus views to be expanded
    # when they do render.)
    expandAllSubcorpora: ->
      @allSubcorporaExpanded = true
      @listenToOnce Backbone, 'subcorpus:subcorpusExpanded',
        @restoreFocusAndScrollPosition
      Backbone.trigger 'subcorporaView:expandAllSubcorpora'

    # Tell all rendered subcorpora to collapse themselves; listen for one
    # notice of collapse from a subcorpus view and respond by restoring the
    # focus and scroll position. (Also tell all un-rendered subcorpus views to
    # be collapsed when they do render.)
    collapseAllSubcorpora: ->
      @allSubcorporaExpanded = false
      @focusEnclosingSubcorpusView()
      @listenToOnce Backbone, 'subcorpus:subcorpusCollapsed',
        @restoreFocusAndScrollPosition
      Backbone.trigger 'subcorporaView:collapseAllSubcorpora'

    # Sets focus to the SubcorpusView div that contains the focused control.
    # This is necessary so that we can restore scroll position after a
    # collapse-all request wherein a previously focused control will become
    # hidden and thus unfocusable.
    focusEnclosingSubcorpusView: ->
      $focusedElement = @$ ':focus'
      if $focusedElement
        $focusedElement.closest('.dative-subcorpus-widget').first().focus()

    # Tell the collection to fetch subcorpora from the server and add them to
    # itself. Only `@render` calls this. Note that we just fetch the subcorpora
    # for the current pagination page, i.e., we use server-side pagination.
    # Note also that setting `fetchSubcorporaLastPage` to `true` will cause
    # `@fetchSubcorporaSuccess` to immediately make a second request for the
    # last page of subcorpora. This is the only way to get the last page of
    # subcorpora from the OLD via its current API; that is, you first have to
    # make a vacuous request in order to get the subcorpus count so that you
    # know what the last page is.
    fetchSubcorporaToCollection: ->
      @fetchSubcorporaLastPage = true
      @fetchSubcorporaPageToCollection()

    # Get a page of subcorpora from an OLD web service. Note that the
    # subcorpora collection only holds one page at a time; that is, the
    # collection is emptied and refilled on each pagination action, hence the
    # `.reset()` call here.
    fetchSubcorporaPageToCollection: ->
      @collection.reset()
      @collection.fetchSubcorpora @paginator

    # Render the pagination top menu view. This is the row of buttons for
    # controlling the visible pagination page and how many items are visible
    # per page.
    renderPaginationMenuTopView: ->
      @paginationMenuTopView.setElement(
        @$('div.dative-pagination-menu-top').first())
      @paginationMenuTopView.render paginator: @paginator
      @rendered @paginationMenuTopView

    # Render the New Subcorpus view.
    renderNewSubcorpusView: ->
      @newSubcorpusview.setElement @$('.new-subcorpus-view').first()
      @newSubcorpusview.render()
      @rendered @newSubcorpusview

    # Close the New Subcorpus view.
    closeNewSubcorpusView: ->
      @newSubcorpusview.close()
      @closed @newSubcorpusview

    ############################################################################
    # Respond to `@collection`-issued events related to the "fetch subcorpora"
    # task.
    ############################################################################

    fetchSubcorporaStart: ->
      @fetchCompleted = false
      @spin()

    fetchSubcorporaEnd: ->
      @fetchCompleted = true

    fetchSubcorporaFail: (reason) ->
      @stopSpin()
      console.log 'fetchSubcorporaFail'
      console.log reason
      @$('.no-subcorpora')
        .show()
        .text reason

    # We have succeeded in retrieving all subcorpora from a FieldDB server.
    # In the FieldDB case we can call `@showLastPage()` because this method
    # is only called once: after all subcorpora have been fetched.
    fetchSubcorporaSuccess: ->
      @saveFetchedMetadata()
      @getSubcorpusViews()
      @setPaginatorItems()
      @showLastPage()
      @stopSpin()

    # We have succeeded in retrieving a page of subcorpora from an OLD server.
    # `paginator` is an object returned from the OLD. Crucially, it has an
    # attribute `count` which tells us how many subcorpora are in the database.
    # `setPaginatorItems` uses this to sync the client-side pagination GUI
    # with the OLD's server-side pagination.
    fetchSubcorporaSuccess: (paginator) ->
      @saveFetchedMetadata()
      @getSubcorpusViews()
      @setPaginatorItems paginator
      if @fetchSubcorporaLastPage
        @fetchSubcorporaLastPage = false
        @showLastPage() # This will fetch the last page and re-call `fetchSubcorporaSuccess`
      else
        @refreshPageFade()

    # Tell the paginator how many items/subcorpora are in our corpus/database.
    setPaginatorItems: (oldPaginator=null) ->
      if oldPaginator
        @paginator.setItems oldPaginator.count # the OLD case
      else
        @paginator.setItems @collection.length # the FieldDB case
      #@paginator.setPageToLast()

    # Remember the server type and name (and corpus name) of the last subcorpora
    # fetch, so we don't needlessly repeat it on future renderings of this
    # entire SubcorporaView. The `@lastFetched` object that is updated here is
    # only accessed by `@weNeedToFetchSubcorporaAgain()` when `@render()` is
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

    # Returns false if we have already fetched these subcorpora; prevents redundant
    # requests.
    weNeedToFetchSubcorporaAgain: ->
      toFetch =
        serverName: @getActiveServerName()
      if _.isEqual(toFetch, @lastFetched) then false else true

    # Refresh the page to reflect the current state. This means refreshing the
    # top menu header of the subcorpora browse page, the pagination sub-header
    # and the list of subcorpora displayed.
    refreshPage: (options) ->
      @refreshHeader()
      @refreshPaginationMenuTop()
      @closeThenOpenCurrentPage options

    # Refresh the page using fade out/in as the animations.
    refreshPageFade: ->
      @refreshPage
        hideEffect: 'fadeOut'
        showEffect: 'fadeIn'

    # Refresh the content of the subcorpora browse header.
    # This is the top "row" of the header, with the "create a new subcorpus"
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
      @$('.no-subcorpora')
        .show()
        .text 'Fetching data from the server ...'
      @$('.pagination-info').hide()
      @$('button.expand-all').button 'disable'
      @$('button.collapse-all').button 'disable'
      @$('button.new-subcorpus').button 'disable'
      @$('button.toggle-all-labels').button 'disable'

    # Configure the header appropriately for the case where there are no
    # subcorpora to browse.
    headerForEmptyDataSet: ->
      @$('.no-subcorpora')
        .show()
        .text 'There are no subcorpora to display'
      @$('.pagination-info').hide()
      @$('button.expand-all').button 'disable'
      @$('button.collapse-all').button 'disable'
      @$('button.toggle-all-labels').button 'disable'
      @setToggleAllLabelsButtonState()
      @setNewSubcorpusViewButtonState()

    # Configure the header appropriately for the case where we have a page
    # that *has* some subcorpora in it.
    headerForContentfulDataSet: ->
      @$('.no-subcorpora').hide()
      @$('.pagination-info').show()
      @$('button.expand-all').button 'enable'
      @$('button.collapse-all').button 'enable'
      @$('button.toggle-all-labels').button 'enable'
      @setToggleAllLabelsButtonState()
      @setNewSubcorpusViewButtonState()
      if @paginator.start is @paginator.end
        @$('.subcorpus-range')
          .text "subcorpus #{@utils.integerWithCommas(@paginator.start + 1)}"
      else
        @$('.subcorpus-range').text "subcorpora
          #{@utils.integerWithCommas(@paginator.start + 1)}
          to
          #{@utils.integerWithCommas(@paginator.end + 1)}"
      @$('.subcorpus-count').text @utils.integerWithCommas(@paginator.items)
      @$('.subcorpus-count-noun').text @utils.pluralizeByNum('subcorpus', @paginator.items)
      @$('.current-page').text @utils.integerWithCommas(@paginator.page)
      @$('.page-count').text @utils.integerWithCommas(@paginator.pages)

    # Tell the pagination menu top view to re-render itself given the current
    # state of the paginator.
    refreshPaginationMenuTop: ->
      @paginationMenuTopView.render paginator: @paginator

    # Hide the current page of subcorpora and provide a `complete` callback which
    # will re-open/draw the page with the new subcorpora, by calling `@renderPage`.
    closeThenOpenCurrentPage: (options) ->
      hideMethod = 'hide'
      hideOptions =
        complete: =>
          @$('.dative-pagin-items').html ''
          @closeRenderedSubcorpusViews()
          @renderPage options
      if options?.hideEffect
        hideOptions.duration = @getAnimationDuration()
        hideMethod = options.hideEffect
      @$('.dative-pagin-items')[hideMethod] hideOptions

    getAnimationDuration: ->
      100 # Better to be fast than try to do something fancy like below...
      # 100 + (10 * @paginator.itemsDisplayed)

    # Close all rendered subcorpus views: remove them from the DOM, but also prevent
    # them from reacting to events.
    closeRenderedSubcorpusViews: ->
      while @renderedSubcorpusViews.length
        subcorpusView = @renderedSubcorpusViews.pop()
        subcorpusView.close()
        @closed subcorpusView

    # Create a `SubcorpusView` instance for each `SubcorpusModel` instance in
    # `@collection` and append it to `@subcorpusViews`.
    # Note that in the OLD case, we reset `subcorpusViews` to `[]` because
    # with server-side pagination we only store one page worth of subcorpus
    # models/views at a time.
    getSubcorpusViews: ->
      if @getActiveServerType() is 'OLD'
        @subcorpusViews = []
      @collection.each (subcorpusModel) =>
        newSubcorpusview = new SubcorpusView
          model: subcorpusModel
          primaryDataLabelsVisible: @primaryDataLabelsVisible
          expanded: @allSubcorporaExpanded
        @subcorpusViews.push newSubcorpusview

    spinnerOptions: ->
      _.extend BaseView::spinnerOptions(), {top: '25%', left: '85.5%'}

    spin: -> @$('#dative-page-header').spin @spinnerOptions()

    stopSpin: -> @$('#dative-page-header').spin false

    setFocus: ->
      if @focusedElementIndex?
        @weShouldFocusFirstAddViewInput = false
        @focusLastFocusedElement()
      else if @weShouldFocusFirstAddViewInput
        @focusFirstNewSubcorpusViewTextarea()
      else
        @focusLastSubcorpus()
      @scrollToFocusedInput()

    focusFirstButton: ->
      @$('button.ui-button').first().focus()

    focusFirstSubcorpus: ->
      @$('div.dative-subcorpus-widget').first().focus()

    focusLastSubcorpus: ->
      if @renderedSubcorpusViews.length > 0
        @renderedSubcorpusViews[@renderedSubcorpusViews.length - 1].$el.focus()

    focusFirstNewSubcorpusViewTextarea: ->
      @$('.new-subcorpus-view .add-subcorpus-widget textarea').first().focus()

    # GUI-fy: make nice buttons and nice titles/tooltips
    guify: ->
      @$('button').button().attr('tabindex', 0)
      @$('button.new-subcorpus')
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
      @$('button.subcorpora-browse-help')
        .button()
        .tooltip
          position:
            my: "left+10 center"
            at: "right center"
            collision: "flipfit"
      @$('button.toggle-all-labels')
        .button()
        .tooltip
          position:
            my: "left+45 center"
            at: "right center"
            collision: "flipfit"

    perfectScrollbar: ->
      @$('#dative-page-body')
        .perfectScrollbar()
        .scroll => @closeAllTooltips()

    refreshPerfectScrollbar: ->
      @$('#dative-page-body').perfectScrollbar 'update'

    # This was an attempt to refresh perfectScrollbar when the height of the
    # pagin items div changes with the goal of stopping the auto-scroll bug. It
    # was successful in calling `refreshPerfectScrollbar` at the appropriate
    # time, but this did not fix the bug.
    monitorPaginItemsHeight: ->
      @paginItemsHeight = @$('.dative-pagin-items').height()
      paginItemsHeightMonitor = =>
        newHeight = @$('.dative-pagin-items').height()
        if newHeight isnt @paginItemsHeight
          @paginItemsHeight = newHeight
          @refreshPerfectScrollbar()
      @paginItemsHeightMonitorId = setInterval paginItemsHeightMonitor, 1000

    onClose: ->
      clearInterval @paginItemsHeightMonitorId

    # Render a page (pagination) of subcorpus views. That is, change which set of
    # `SubcorpusView` instances are displayed.
    renderPage: (options) ->
      # @paginator._refresh() # This seems to be unnecessary.
      @renderSubcorpusViews()
      @stopSpin()
      @showSubcorpusList options

    # Render all subcorpus views on the current paginator page.
    # Note the OLD/FieldDB difference: with the OLD, each pagination change
    # event triggers a new fetch to the OLD server, and a resetting of both
    # `@collection` and `@subcorpusViews`; thus we render all subcorpus models in the
    # collection (and all subcorpus views in `@subcorpusViews`) using the "indices"
    # from `@paginator`. With FieldDB, we have already fetched *all*
    # subcorpora to `@collection` (and we have all of their respective views
    # in `@subcorpusViews`) so we can simply take a slice out of
    # `@subcorpusViews` using the paginator start and end values.
    renderSubcorpusViews: ->
      paginationIndices = [@paginator.start..@paginator.end]
      if @getActiveServerType() is 'OLD'
        for [index, subcorpusView] in _.zip(paginationIndices, @subcorpusViews)
          @renderSubcorpusView subcorpusView, index
      else
        for index in paginationIndices
          subcorpusView = @subcorpusViews[index]
          @renderSubcorpusView subcorpusView, index

    # Render a single subcorpus view.
    renderSubcorpusView: (subcorpusView, index) ->
      $subcorpusList = @$ '.dative-pagin-items'
      if subcorpusView # subcorpusView may be undefined.
        subcorpusId = subcorpusView.model.get 'id'
        $subcorpusList.append subcorpusView.render().el
        @renderedSubcorpusViews.push subcorpusView
        @rendered subcorpusView

    # jQuery-show the list of subcorpora.
    showSubcorpusList: (options) ->
      $subcorpusList = @$ '.dative-pagin-items'
      if options?.showEffect
        $subcorpusList[options.showEffect]
          duration: @getAnimationDuration()
          complete: =>
            @setFocus()
      else
        $subcorpusList.show()
        @setFocus()


    ############################################################################
    # Respond to requests from the Pagination Menu Top View
    ############################################################################

    changeItemsPerPage: (newItemsPerPage) ->
      Backbone.trigger 'subcorporaView:itemsPerPageChange', newItemsPerPage
      @itemsPerPage = newItemsPerPage
      itemsDisplayedBefore = @paginator.itemsDisplayed
      @paginator.setItemsPerPage newItemsPerPage
      itemsDisplayedAfter = @paginator.itemsDisplayed
      if itemsDisplayedBefore isnt itemsDisplayedAfter
        if @getActiveServerType() is 'FieldDB'
          @refreshPageFade()
        else
          @fetchSubcorporaPageToCollection()

    showFirstPage: ->
      pageBefore = @paginator.page
      @paginator.setPageToFirst()
      pageAfter = @paginator.page
      if pageBefore isnt pageAfter
        if @getActiveServerType() is 'FieldDB'
          @refreshPageFade()
        else
          @fetchSubcorporaPageToCollection()

    showPreviousPage: ->
      pageBefore = @paginator.page
      @paginator.setPageToPrevious()
      pageAfter = @paginator.page
      if pageBefore isnt pageAfter
        if @getActiveServerType() is 'FieldDB'
          @refreshPageFade()
        else
          @fetchSubcorporaPageToCollection()

    showNextPage: ->
      pageBefore = @paginator.page
      @paginator.setPageToNext()
      pageAfter = @paginator.page
      if pageBefore isnt pageAfter
        if @getActiveServerType() is 'FieldDB'
          @refreshPageFade()
        else
          @fetchSubcorporaPageToCollection()

    showLastPage: ->
      pageBefore = @paginator.page
      @paginator.setPageToLast()
      pageAfter = @paginator.page
      if pageBefore isnt pageAfter
        if @getActiveServerType() is 'FieldDB'
          @refreshPageFade()
        else
          @fetchSubcorporaPageToCollection()

    # Show a new page where `method` determines whether the new page is
    # behind or ahead of the current one and where `n` is the number of
    # pages behind or ahead.
    showPage: (n, method) ->
      pageBefore = @paginator.page
      @paginator[method] n
      pageAfter = @paginator.page
      if pageBefore isnt pageAfter
        if @getActiveServerType() is 'FieldDB'
          @refreshPageFade()
        else
          @fetchSubcorporaPageToCollection()

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
    # Show, hide and toggle the Subcorpus Add widget view
    ############################################################################

    # Make the SubcorpusAddWidgetView visible or not, depending on its last
    # state.
    newSubcorpusViewVisibility: ->
      if @newSubcorpusViewVisible
        @showNewSubcorpusView()
      else
        @hideNewSubcorpusView()

    hideNewSubcorpusView: ->
      @setNewSubcorpusViewButtonShow()
      @newSubcorpusViewVisible = false
      @$('.new-subcorpus-view').hide()

    showNewSubcorpusView: ->
      @setNewSubcorpusViewButtonHide()
      @newSubcorpusViewVisible = true
      @$('.new-subcorpus-view').show
        complete: =>
          @newSubcorpusview.showUpdateView()
          Backbone.trigger 'addSubcorpusWidgetVisible'

    hideNewSubcorpusViewAnimate: ->
      @setNewSubcorpusViewButtonShow()
      @newSubcorpusViewVisible = false
      @$('.new-subcorpus-view').slideUp()
      @newSubcorpusview.closeAllTooltips()
      @focusLastSubcorpus()
      @scrollToFocusedInput()

    showNewSubcorpusViewAnimate: ->
      @setNewSubcorpusViewButtonHide()
      @newSubcorpusViewVisible = true
      @$('.new-subcorpus-view').slideDown
        complete: =>
          @newSubcorpusview.showUpdateViewAnimate()
          Backbone.trigger 'addSubcorpusWidgetVisible'
      @focusFirstNewSubcorpusViewTextarea()
      @scrollToFocusedInput()

    toggleNewSubcorpusViewAnimate: ->
      if @$('.new-subcorpus-view').is ':visible'
        @hideNewSubcorpusViewAnimate()
      else
        @showNewSubcorpusViewAnimate()

    setNewSubcorpusViewButtonState: ->
      if @newSubcorpusViewVisible
        @setNewSubcorpusViewButtonHide()
      else
        @setNewSubcorpusViewButtonShow()

    setNewSubcorpusViewButtonShow: ->
      @$('button.new-subcorpus')
        .button 'enable'
        .tooltip
          content: 'create a new subcorpus'

    # The subcorpus add view show "+" button is disabled when the view is visible; to
    # hide the view, you click on the ^ button on the view itself.
    setNewSubcorpusViewButtonHide: ->
      @$('button.new-subcorpus')
        .button 'disable'

    showNewSubcorpusViewAnimate: ->
      @setNewSubcorpusViewButtonHide()
      @newSubcorpusViewVisible = true
      @$('.new-subcorpus-view').slideDown
        complete: =>
          @newSubcorpusview.showUpdateViewAnimate()
          Backbone.trigger 'addSubcorpusWidgetVisible'
      @focusFirstNewSubcorpusViewTextarea()
      @scrollToFocusedInput()

    # Duplicate the supplied subcorpus model, but display a confirm dialog first if the
    # new subcorpus view has data in it.
    duplicateSubcorpusConfirm: (subcorpusModel) ->
      if @newSubcorpusview.model.isEmpty()
        @duplicateSubcorpus subcorpusModel
      else
        id = subcorpusModel.get 'id'
        options =
          text: "The “new subcorpus” subcorpus has unsaved data in it. If you proceed
            with duplicating subcorpus #{id}, you will lose that unsaved information.
            Click “Cancel” to abort the duplication so you can save your
            unsaved new subcorpus first. If you are okay with discarding your unsaved
            new subcorpus, then click “Ok” to proceed with duplicating subcorpus #{id}."
          confirm: true
          confirmEvent: 'duplicateSubcorpus'
          confirmArgument: subcorpusModel
        Backbone.trigger 'openAlertDialog', options

    # Duplicate a subcorpus model and display it for editing in the "New Subcorpus"
    # widget.
    duplicateSubcorpus: (subcorpusModel) ->
      newSubcorpusModel = subcorpusModel.clone()

      # Remove the server-generated attributes of the subcorpus. Note: there are
      # other attributes that are server-generated but I'm unsure if these
      # should be removed here (they will be regenerated by the OLD upon save):
      # morpheme_break_ids, morpheme_gloss_ids, break_gloss_category,
      # syntactic_category_string.
      newSubcorpusModel.set
        id: null
        UUID: ''
        datetime_entered: ''
        datetime_modified: ''
        enterer: null
        modifier: null
        collections: []

      # TODO: if the current New Subcorpus view has a non-empty model we should
      # either warn the user about that or we should intelligently store that
      # model for later ...

      @hideNewSubcorpusViewAnimate()
      @closeNewSubcorpusView()
      @newSubcorpusview = @getNewSubcorpusView newSubcorpusModel
      @renderNewSubcorpusView()
      @listenToNewSubcorpusView()
      @showNewSubcorpusViewAnimate()

    openExporterDialog: (options) ->
      @exporterDialog.setToBeExported options
      @exporterDialog.generateExport()
      @exporterDialog.dialogOpen()


