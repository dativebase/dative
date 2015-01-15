define [
  'backbone'
  './base'
  './form'
  './pagination-menu-top'
  './pagination-item-table'
  './../collections/forms'
  './../templates/forms'
  'perfectscrollbar'
], (Backbone, BaseView, FormView, PaginationMenuTopView,
  PaginationItemTableView, FormsCollection, formsTemplate) ->

  # Forms View
  # -----------
  #
  # Displays a list of forms.

  class FormsView extends BaseView

    template: formsTemplate

    initialize: (options) ->
      @focusedElementIndex = null
      @paginationMenuTopView = new PaginationMenuTopView pagination: @pagination
      @applicationSettings = options.applicationSettings
      @getActiveServerType()
      @collection = new FormsCollection()
      @collection.applicationSettings = @applicationSettings
      @formViews = []
      @listenToEvents()

    events: {}

    listenToEvents: ->
      @stopListening()
      @undelegateEvents()
      @delegateEvents()
      @listenTo Backbone, 'fetchAllFieldDBFormsStart', @fetchAllFormsStart
      @listenTo Backbone, 'fetchAllFieldDBFormsEnd', @fetchAllFormsEnd
      @listenTo Backbone, 'fetchAllFieldDBFormsSuccess', @fetchAllFormsSuccess

    render: (taskId) ->
      @$el.html @template(pagination: @pagination)
      @matchHeights()
      @guify()
      @renderPaginationMenuTopView()
      @collection.fetchAllFieldDBForms()
      @listenToEvents()
      @perfectScrollbar()
      @setFocus()
      Backbone.trigger 'longTask:deregister', taskId
      @

    renderPaginationMenuTopView: ->
      @paginationMenuTopView.setElement @$('div.dative-pagination-menu-top').first()
      @paginationMenuTopView.render pagination: @pagination
      @rendered @paginationMenuTopView

    fetchAllFormsStart: ->
      @spin 'fetching all forms'

    fetchAllFormsEnd: ->
      @stopSpin()

    fetchAllFormsSuccess: ->
      @editHeaderInfo()
      @paginationMenuTopView.render pagination: @pagination
      @getFormViews()
      @renderPage()

    getFormViews: ->
      @collection.each (formModel) =>
        newFormView = new FormView
          model: formModel
          applicationSettings: @applicationSettings
        @formViews.push newFormView

    spinnerOptions: ->
      _.extend BaseView::spinnerOptions, {top: '25%', left: '98%'}

    spin: (tooltipMessage) ->
      @$('#dative-page-header')
        .spin @spinnerOptions()
        .tooltip
          items: 'div'
          content: tooltipMessage
          position:
            my: "left+10 center"
            at: "right top+20"
            collision: "flipfit"
        .tooltip 'open'

    stopSpin: ->
      $header = @$('#dative-page-header')
      $header.spin false
      if $header.tooltip 'instance' then $header.tooltip 'destroy'

    getActiveServerType: ->
      if @applicationSettings.get('activeServer').get('type') is 'FieldDB'
        @activeServerType = 'FieldDB'
        @activeFieldDBCorpus = @applicationSettings.get 'activeFieldDBCorpus'
      else
        @activeServerType = 'OLD'

    pagination:
      items: 0
      itemsPerPage: 10
      page: 1
      pages: 0

    setFocus: ->
      if @focusedElementIndex
        @focusLastFocusedElement()
      else
        @focusFirstButton()

    focusFirstButton: ->
      @$('button.ui-button').first().focus()

    guify: ->

      @$('button').button().attr('tabindex', 0)

      @$('button.expand-all')
        .button()
        .tooltip
          position:
            my: "right-10 center"
            at: "left center"
            collision: "flipfit"

      @$('button.collapse-all')
        .button()
        .tooltip
          position:
            my: "right-45 center"
            at: "left center"
            collision: "flipfit"

    perfectScrollbar: ->
      @$('#dative-page-body')
        .perfectScrollbar()
        .scroll => @closeAllTooltips()

    # Render a page (pagination) of form views.
    renderPage: ->
      start = (@pagination.page - 1) * @pagination.itemsPerPage
      end = start + @pagination.itemsPerPage - 1
      $formList = @$('.dative-pagin-items')
      for formView, index in @formViews[start..end]
        formId = formView.model.get('id')
        paginationItemTableView = new PaginationItemTableView
          formId: formId
          index: index + 1
        $formList.append paginationItemTableView.render().el
        formView.setElement @$("##{formId}")
        formView.render()
        @rendered formView
        @rendered paginationItemTableView

    editHeaderInfo: ->
      @pagination.items = @collection.length
      @pagination.pages = Math.ceil(@pagination.items / @pagination.itemsPerPage)
      @$('.items-per-page').text @utils.integerWithCommas(@pagination.itemsPerPage)
      @$('.form-count').text @utils.integerWithCommas(@pagination.items)
      @$('.page-count').text @utils.integerWithCommas(@pagination.pages)

    # Deprecated?
    appendView: (model, index) ->
      formView = new FormView model: model
      formView.render()
      @formViews.push formView
      @rendered formView
      @$('.dative-pagin-items').append @paginItemTable(formView.$el, index)

    # Deprecated?
    closeRenderedForms: ->
      while @formViews.length
        formView = @formViews.pop()
        formView.close()
        @closed formView

    # Return the form view wrapped in a pagination item <table>
    paginItemTable: (formView$el, index) ->
      $('<table>')
        .addClass('dative-pagin-item')
        .append($('<tbody>')
          .append($('<tr>')
            .append($('<td>')
              .addClass('dative-pagin-item-index')
              .text("(#{index + 1})"))
            .append($('<td>')
              .addClass('dative-pagin-item-content')
              .html(formView$el))))

