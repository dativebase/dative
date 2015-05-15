define [
  './base'
  './../templates/extra-actions'
], (BaseView, extraActionsTemplate) ->

  # Extra Actions View
  # ------------------
  #
  # View for a widget containing inputs and controls for manipulating the extra
  # actions of a resource, actions like requesting parses or generating FST
  # scripts. This base class is justified by the fact that many resources have
  # "extra actions".

  class ExtraActionsView extends BaseView

    template: extraActionsTemplate
    className: 'resource-actions-widget dative-widget-center
      dative-shadowed-widget ui-widget ui-widget-content ui-corner-all'

    # An array of action view classes. Subclasses should override this with
    # suitable action views for the resource concerned.
    actionViewClasses: []

    initialize: (options) ->
      @activeServerType = @getActiveServerType()
      @getActionViews()
      @listenToEvents()

    getActionViews: ->
      @actionViews = []
      for actionViewClass in @actionViewClasses
        actionView = new actionViewClass model: @model
        @actionViews.push actionView

    events:
      'click button.hide-resource-actions-widget': 'hideSelf'
      'keydown':                                   'keydown'

    render: ->
      @html()
      @renderActionViews()
      @guify()
      @listenToEvents()
      @

    html: ->
      context =
        headerTitle: 'Extra Actions'
        activeServerType: @activeServerType
      @$el.html @template(context)

    renderActionViews: ->
      container = document.createDocumentFragment()
      for actionView in @actionViews
        container.appendChild actionView.render().el
        @rendered actionView
      @$('div.resource-actions-container').html container

    guify: ->
      @fixRoundedBorders() # defined in BaseView
      @$el.css 'border-color': @constructor.jQueryUIColors().defBo
      @$('button').button()
      @tooltipify()

    tooltipify: ->
      @$('.button-container-right .dative-tooltip')
        .tooltip position: @tooltipPositionRight('+20')
      @$('.button-container-left .dative-tooltip')
        .tooltip position: @tooltipPositionLeft('-20')

    # The resource super-view will handle this hiding.
    hideSelf: -> @trigger "extraActionsView:hide"

    # ESC hides the extra actions widget
    keydown: (event) ->
      event.stopPropagation()
      switch event.which
        when 27
          @stopEvent event
          @hideSelf()

    spinnerOptions: (top='50%', left='-170%') ->
      options = super
      options.top = top
      options.left = left
      options.color = @constructor.jQueryUIColors().defCo
      options

    spin: (selector='.spinner-container', top='50%', left='-170%') ->
      @$(selector).spin @spinnerOptions(top, left)

    stopSpin: (selector='.spinner-container') ->
      @$(selector).spin false

