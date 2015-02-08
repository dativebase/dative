define [
  'backbone'
  './base'
  './form'
  './form-add-widget'
  './pagination-menu-top'
  './pagination-item-table'
  './../collections/forms'
  './../models/form'
  './../utils/paginator'
  './../utils/globals'
  './../templates/forms'
  'perfectscrollbar'
], (Backbone, BaseView, FormView, FormAddWidgetView, PaginationMenuTopView,
  PaginationItemTableView, FormsCollection, FormModel, Paginator, globals,
  formsTemplate) ->

  # Forms View
  # -----------
  #
  # Displays a list of forms (with pagination).

  class FormsView extends BaseView

    template: formsTemplate

    initialize: (options) ->
      @focusedElementIndex = null
      @formViews = [] # holds a FormView instance for each FormModel in FormsCollection
      @renderedFormViews = [] # references to the FormView instances that are rendered
      @formAddView = new FormAddWidgetView model: new FormModel()
      @formAddViewVisible = false
      @weShouldFocusFirstAddViewInput = false
      @renderedPaginationItemTableViews = [] # Each form is in a 1-row/2-cell table where cell 1 is the index+1, e.g., (1), (2), etc.
      @fetchCompleted = false
      @lastFetched = # We store this to help us prevent redundant requests to the server for all forms.
        serverType: ''
        serverName: ''
        fieldDBCorpusPouchname: ''
      @paginator = new Paginator()
      @paginationMenuTopView = new PaginationMenuTopView paginator: @paginator # This handles the UI for the items-per-page select, the first, prevous, next buttons, etc.
      @applicationSettings = options.applicationSettings
      @activeFieldDBCorpus = options.activeFieldDBCorpus
      @getActiveServerType()
      @collection = new FormsCollection()
      @collection.applicationSettings = @applicationSettings
      @collection.activeFieldDBCorpus = @activeFieldDBCorpus
      @listenToEvents()

    controlFocused: (event) ->
      @rememberFocusedElement event
      @scrollToFocusedInput event

    events:
      # 'focus .dative-form-object, input, textarea, .ui-selectmenu-button, button':
      #   'rememberFocusedElement'
      # 'focus .dative-form-object, input, textarea, .ui-selectmenu-button, button':
      #   'scrollToFocusedInput'
      'focus .dative-form-object, input, textarea, .ui-selectmenu-button, button':
        'controlFocused'
      'click .expand-all': 'expandAllForms'
      'click .collapse-all': 'collapseAllForms'
      'click .new-form': 'showFormAddViewAnimate'
      'click .forms-browse-help': 'openFormsBrowseHelp'
      'keydown': 'keyboardShortcuts'

    # Tell the Help dialog to open itself and search for "browsing forms" and
    # scroll to the second match. WARN: this is brittle because if the help
    # HTML changes, then the second match may not be what we want
    openFormsBrowseHelp: ->
      Backbone.trigger(
        'helpDialog:toggle',
        searchTerm: 'browsing forms'
        scrollToIndex: 1
      )

    # These are the focusable elements in the forms browse interface.
    focusableSelector: 'textarea, button, input, .ui-selectmenu-button, .dative-form-object'

    expandAllForms: ->
      @listenToOnce Backbone, 'form:formExpanded', @restoreFocusAndScrollPosition
      Backbone.trigger 'formsView:expandAllForms'

    restoreFocusAndScrollPosition: ->
      @focusLastFocusedElement()
      @scrollToFocusedInput()

    collapseAllForms: ->
      @listenToOnce Backbone, 'form:formCollapsed', @restoreFocusAndScrollPosition
      Backbone.trigger 'formsView:collapseAllForms'

    formAddViewVisibility: ->
      if @formAddViewVisible
        @showFormAddView()
      else
        @hideFormAddView()

    hideFormAddView: ->
      @setFormAddViewButtonShow()
      @formAddViewVisible = false
      @$('.add-form-widget').hide()

    showFormAddView: ->
      @setFormAddViewButtonHide()
      @formAddViewVisible = true
      @$('.add-form-widget').show()
      #@focusFirstFormAddViewTextarea()

    hideFormAddViewAnimate: ->
      @setFormAddViewButtonShow()
      @formAddViewVisible = false
      @$('.add-form-widget').slideUp()
      @formAddView.closeAllTooltips()
      @focusFirstForm()
      @scrollToTop()

    showFormAddViewAnimate: ->
      @setFormAddViewButtonHide()
      @formAddViewVisible = true
      @$('.add-form-widget').slideDown()
      @focusFirstFormAddViewTextarea()

    toggleFormAddViewAnimate: ->
      if @$('.add-form-widget').is ':visible'
        @hideFormAddViewAnimate()
      else
        @showFormAddViewAnimate()

    setFormAddViewButtonState: ->
      if @formAddViewVisible
        @setFormAddViewButtonHide()
      else
        @setFormAddViewButtonShow()

    setFormAddViewButtonShow: ->
      @$('button.new-form')
        .button 'enable'
        .tooltip
          content: 'create a new form'

    setFormAddViewButtonHide: ->
      @$('button.new-form')
        .button 'disable'

    listenToEvents: ->
      @stopListening()
      @undelegateEvents()
      @delegateEvents()

      @listenTo Backbone, 'fetchAllFieldDBFormsStart', @fetchAllFormsStart
      @listenTo Backbone, 'fetchAllFieldDBFormsEnd', @fetchAllFormsEnd
      @listenTo Backbone, 'fetchAllFieldDBFormsFail', @fetchAllFormsFail
      @listenTo Backbone, 'fetchAllFieldDBFormsSuccess', @fetchAllFormsSuccess

      @listenTo Backbone, 'fetchOLDFormsStart', @fetchAllFormsStart
      @listenTo Backbone, 'fetchOLDFormsEnd', @fetchAllFormsEnd
      @listenTo Backbone, 'fetchOLDFormsSuccess', @fetchAllFormsSuccess

      @listenTo @paginationMenuTopView, 'paginator:changeItemsPerPage', @changeItemsPerPage
      @listenTo @paginationMenuTopView, 'paginator:showFirstPage', @showFirstPage
      @listenTo @paginationMenuTopView, 'paginator:showLastPage', @showLastPage
      @listenTo @paginationMenuTopView, 'paginator:showPreviousPage', @showPreviousPage
      @listenTo @paginationMenuTopView, 'paginator:showNextPage', @showNextPage
      @listenTo @paginationMenuTopView, 'paginator:showThreePagesBack', @showThreePagesBack
      @listenTo @paginationMenuTopView, 'paginator:showTwoPagesBack', @showTwoPagesBack
      @listenTo @paginationMenuTopView, 'paginator:showOnePageBack', @showOnePageBack
      @listenTo @paginationMenuTopView, 'paginator:showOnePageForward', @showOnePageForward
      @listenTo @paginationMenuTopView, 'paginator:showTwoPagesForward', @showTwoPagesForward
      @listenTo @paginationMenuTopView, 'paginator:showThreePagesForward', @showThreePagesForward

      @listenTo @formAddView, 'formAddView:hide', @hideFormAddViewAnimate

    # The FormsView is here directly manipulating the GUI domain of the Pagination
    # Top Menu in order to implement some of these keyboard shortcuts. This seems
    # better than an overload of message passing, but we may want to change this
    # later.
    # WARN: TODO: @jrwdunham: some of these keyboard shortcuts should only work if
    # user-editable fields are *not* open. That is, we do not want "n" to bring us
    # to the next page if we are editing a form and type the character "n". This may
    # now be handled by the `if not @addFormWidgetHasFocus()` condition.
    # TODO: @jrwdunham @cesine: consider changing the shortcut keys: vim-style
    # conventions or arrow keys might be better. Alternatively (or in
    # addition), we could have these be user-customizable. 
    # TODO: up and down arrows should not expand/contract all when a
    # (items-per-page) selectmenu is in focus.
    keyboardShortcuts: (event) ->
      if not @addFormWidgetHasFocus()
        if not event.ctrlKey
          switch event.which
            when 70 then @$('.first-page').click() # f
            when 80 then @$('.previous-page').click() # p
            when 78 then @$('.next-page').click() # n
            when 76 then @$('.last-page').click() # l
            when 40 then @$('.expand-all').click() # down arrow
            when 38 then @$('.collapse-all').click() # up arrow
            when 65 then @toggleFormAddViewAnimate() # a

    addFormWidgetHasFocus: ->
      @$('.add-form-widget').find(':focus').length > 0

    render: (taskId) ->
      context =
        pluralizeByNum: @utils.pluralizeByNum
        paginator: @paginator
      @$el.html @template(context)
      @matchHeights()
      @guify()
      @refreshHeader()
      @renderPaginationMenuTopView()
      @renderFormAddView()
      @formAddViewVisibility()
      if @weNeedToFetchFormsAgain()
        @fetchFormsToCollection()
      else
        @refreshPage()
      @listenToEvents()
      @perfectScrollbar()
      @setFocus()
      Backbone.trigger 'longTask:deregister', taskId
      @

    fetchFormsToCollection: ->
      if @getActiveServerType() is 'FieldDB'
        @collection.fetchAllFieldDBForms()
      else
        @collection.fetchOLDForms()

    renderPaginationMenuTopView: ->
      @paginationMenuTopView.setElement @$('div.dative-pagination-menu-top').first()
      @paginationMenuTopView.render paginator: @paginator
      @rendered @paginationMenuTopView

    renderFormAddView: ->
      @formAddView.setElement @$('.add-form-widget').first()
      @formAddView.render()
      @rendered @formAddView

    fetchAllFormsStart: ->
      @fetchCompleted = false
      @spin()

    fetchAllFormsEnd: ->
      @fetchCompleted = true
      @stopSpin()

    fetchAllFormsFail: (reason) ->
      @$('.no-forms')
        .show()
        .text reason

    fetchAllFormsSuccess: ->
      @saveFetchedMetadata()
      @getFormViews()
      @refreshPage()

    # Remember the server type (and corpus name) of the last fetch, so we don't needlessly
    # repeat it on future renderings.
    saveFetchedMetadata: ->
      @lastFetched.serverType = @getActiveServerType()
      @lastFetched.serverName = @getActiveServerName()
      @lastFetched.fieldDBCorpusPouchname = @getActiveServerFieldDBCorpusPouchname()

    getActiveServerType: ->
      globals.applicationSettings.get('activeServer').get 'type'

    getActiveServerName: ->
      globals.applicationSettings.get('activeServer').get 'name'

    getActiveServerFieldDBCorpusPouchname: ->
      if @getActiveServerType() is 'FieldDB'
        globals.applicationSettings.get 'activeFieldDBCorpus'
      else
        null

    # Returns false if we have already fetched these forms; prevents redundant
    # requests.
    weNeedToFetchFormsAgain: ->
      toFetch =
        serverType: @getActiveServerType()
        serverName: @getActiveServerName()
        fieldDBCorpusPouchname: @getActiveServerFieldDBCorpusPouchname()
      if _.isEqual(toFetch, @lastFetched) then false else true

    refreshPage: (options) ->
      @refreshHeader()
      @refreshPaginationMenuTop()
      @closeThenOpenCurrentPage options

    closeThenOpenCurrentPage: (options) ->
      hideMethod = 'hide'
      hideOptions =
        complete: =>
          @$('.dative-pagin-items').html ''
          @closeRenderedFormViews()
          @closeRenderedPaginationItemTableViews()
          @renderPage options
      if options?.hideEffect
        hideOptions.duration = @getAnimationDuration()
        hideMethod = options.hideEffect
      @$('.dative-pagin-items')[hideMethod] hideOptions

    getAnimationDuration: ->
      100
      #100 + (10 * @paginator.itemsDisplayed)

    closeRenderedFormViews: ->
      while @renderedFormViews.length
        formView = @renderedFormViews.pop()
        formView.close()
        @closed formView

    closeRenderedPaginationItemTableViews: ->
      while @renderedPaginationItemTableViews.length
        paginationItemTableView = @renderedPaginationItemTableViews.pop()
        paginationItemTableView.close()
        @closed paginationItemTableView

    refreshPaginationMenuTop: ->
      @paginationMenuTopView.render paginator: @paginator

    # TODO: @cesine @jrwdunham instantiating a FormView for every FormModel
    # in the collection seems potentially inefficient. Thoughts?
    getFormViews: ->
      @collection.each (formModel) =>
        newFormView = new FormView
          model: formModel
          applicationSettings: @applicationSettings
        #@formViews.push newFormView # What we used to do.
        # Do this because we want the most recent forms first.
        # NOTE: I think we should really be able to do this ordering via the
        # server request: in the FieldDB case, this would mean defining a new
        # CouchDB view for datums_chronological_reverse (@cesine?)
        @formViews.unshift newFormView

    spinnerOptions: ->
      _.extend BaseView::spinnerOptions(), {top: '25%', left: '93.5%'}

    spin: -> @$('#dative-page-header').spin @spinnerOptions()

    stopSpin: -> @$('#dative-page-header').spin false

    # ISSUE: @jrwdunham: because the paginator buttons can become dis/enabled
    # based on the paginator state, the setFocus can behave erratically, since
    # it sets focus based on the remembered index of a jQuery matched set.
    setFocus: ->
      if @focusedElementIndex?
        @weShouldFocusFirstAddViewInput = false
        @focusLastFocusedElement()
      else if @weShouldFocusFirstAddViewInput
        @focusFirstFormAddViewTextarea()
      else
        @focusFirstForm()

    focusFirstButton: ->
      @$('button.ui-button').first().focus()

    focusFirstForm: ->
      @$('div.dative-form-object').first().focus()

    focusFirstFormAddViewTextarea: ->
      @$('.add-form-widget textarea').first().focus()

    guify: ->

      @$('button').button().attr('tabindex', 0)

      @$('button.new-form')
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

      @$('button.forms-browse-help')
        .button()
        .tooltip
          position:
            my: "left+10 center"
            at: "right center"
            collision: "flipfit"

    perfectScrollbar: ->
      @$('#dative-page-body')
        .perfectScrollbar()
        .scroll => @closeAllTooltips()

    # Render a page (pagination) of form views.
    renderPage: (options) ->
      @paginator._refresh() # TODO: NECESSARY?
      $formList = @$('.dative-pagin-items')
      for index in [@paginator.start..@paginator.end]
        formView = @formViews[index]
        if formView # formView may be undefined.
          formId = formView.model.get 'id'
          paginationItemTableView = new PaginationItemTableView
            formId: formId
            index: index + 1
          $formList.append paginationItemTableView.render().el
          formView.setElement @$("##{formId}")
          formView.render()
          @renderedFormViews.push formView
          @rendered formView
          @renderedPaginationItemTableViews.push paginationItemTableView
          @rendered paginationItemTableView
      @stopSpin()

      if options?.showEffect
        $formList[options.showEffect]
          duration: @getAnimationDuration()
          complete: =>
            @setFocus()
      else
        $formList.show()
        @setFocus()

    # Refresh the content of the forms browse header.
    # This is the top "row" of the header, with the "create a new form"
    # button, the "expand/collapse all" buttons and the title.
    # (Note that the pagination controls are handled by a separate view.
    refreshHeader: ->
      if not @fetchCompleted
        @$('.no-forms')
          .show()
          .text 'Fetching data from the server ...'
        @$('.pagination-info').hide()
        @$('button.expand-all').button 'disable'
        @$('button.collapse-all').button 'disable'
        @$('button.new-form').button 'disable'
        return
      @paginator.setItems @collection.length
      if @paginator.items is 0
        @$('.no-forms')
          .show()
          .text 'There are no forms to display'
        @$('.pagination-info').hide()
        @$('button.expand-all').button 'disable'
        @$('button.collapse-all').button 'disable'
        # @$('button.new-form').button 'enable'
        @setFormAddViewButtonState()
      else
        @$('.no-forms').hide()
        @$('.pagination-info').show()
        @$('button.expand-all').button 'enable'
        @$('button.collapse-all').button 'enable'
        # @$('button.new-form').button 'enable'
        @setFormAddViewButtonState()
        if @paginator.start is @paginator.end
          @$('.form-range')
            .text "form #{@utils.integerWithCommas(@paginator.start + 1)}"
        else
          @$('.form-range').text ["forms",
            "#{@utils.integerWithCommas(@paginator.start + 1)}",
            "to",
            "#{@utils.integerWithCommas(@paginator.end + 1)}"].join ' '
        @$('.form-count').text @utils.integerWithCommas(@paginator.items)
        @$('.form-count-noun').text @utils.pluralizeByNum('form', @paginator.items)
        @$('.page-count').text @utils.integerWithCommas(@paginator.pages)
        @$('.page-count-noun').text @utils.pluralizeByNum('page', @paginator.pages)

    changeItemsPerPage: (newItemsPerPage) ->
      itemsDisplayedBefore = @paginator.itemsDisplayed
      @paginator.setItemsPerPage newItemsPerPage
      itemsDisplayedAfter = @paginator.itemsDisplayed
      if itemsDisplayedBefore isnt itemsDisplayedAfter
        @refreshPage
          hideEffect: 'fadeOut'
          showEffect: 'fadeIn'

    showFirstPage: ->
      pageBefore = @paginator.page
      @paginator.setPageToFirst()
      pageAfter = @paginator.page
      if pageBefore isnt pageAfter
        @refreshPage
          hideEffect: 'fadeOut'
          showEffect: 'fadeIn'

    showPreviousPage: ->
      pageBefore = @paginator.page
      @paginator.setPageToPrevious()
      pageAfter = @paginator.page
      if pageBefore isnt pageAfter
        @refreshPage
          hideEffect: 'fadeOut'
          showEffect: 'fadeIn'

    showNextPage: ->
      pageBefore = @paginator.page
      @paginator.setPageToNext()
      pageAfter = @paginator.page
      if pageBefore isnt pageAfter
        @refreshPage
          hideEffect: 'fadeOut'
          showEffect: 'fadeIn'

    showLastPage: ->
      pageBefore = @paginator.page
      @paginator.setPageToLast()
      pageAfter = @paginator.page
      if pageBefore isnt pageAfter
        @refreshPage
          hideEffect: 'fadeOut'
          showEffect: 'fadeIn'

    # Show a new page where `method` determines whether the new page is
    # behind or ahead of the current one and where `n` is the number of
    # pages behind or ahead.
    showPage: (n, method) ->
      pageBefore = @paginator.page
      @paginator[method] n
      pageAfter = @paginator.page
      if pageBefore isnt pageAfter
        @refreshPage
          hideEffect: 'fadeOut'
          showEffect: 'fadeIn'

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

