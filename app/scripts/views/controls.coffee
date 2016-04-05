define [
  './base'
  './../templates/controls'
], (BaseView, controlsTemplate) ->

  # Controls View
  # ------------------
  #
  # View for a widget containing inputs and controls for manipulating the
  # controls of a resource, i.e., actions like requesting parses or generating
  # FST scripts. This base class is justified by the fact that many resources
  # have controls, or "controls".

  class ControlsView extends BaseView

    template: controlsTemplate
    className: 'controls-widget dative-widget-center
      dative-shadowed-widget ui-widget ui-widget-content ui-corner-all'

    # An array of action view classes. Subclasses should override this with
    # suitable action views for the resource concerned.
    actionViewClasses: []

    initialize: (options) ->
      @resourceName = options?.resourceName or ''
      @resourceNameHumanReadable =
        options?.resourceNameHumanReadable or @resourceName
      @activeServerType = @getActiveServerType()
      @getActionViews()
      @listenToEvents()

    getActionViews: ->
      @actionViews = []
      for actionViewClass in @actionViewClasses
        actionView = new actionViewClass model: @model
        @actionViews.push actionView

    events:
      'click button.hide-controls-widget': 'hideSelf'
      'click button.controls-help':        'openControlsHelp'
      'keydown':                           'keydown'

    # Tell the Help dialog to open itself and search for
    # "<resource-name-plural> controls" and scroll to the second match. WARN:
    # this is brittle because if the help HTML changes, then the second match
    # may not be what we want...
    openControlsHelp: ->
      searchTerm = "#{@utils.snake2regular @resourceName} controls"
      Backbone.trigger(
        'helpDialog:openTo',
        searchTerm: searchTerm
        scrollToIndex: 1
      )

    render: ->
      @html()
      @renderActionViews()
      @guify()
      @listenToEvents()
      @

    html: ->
      context =
        resourceName: @resourceName
        resourceNameHumanReadable: @resourceNameHumanReadable
        headerTitle: 'Controls'
        activeServerType: @activeServerType
      @$el.html @template(context)

    renderActionViews: ->
      container = document.createDocumentFragment()
      for actionView in @actionViews
        container.appendChild actionView.render().el
        @rendered actionView
      @$('div.controls-container').html container

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
    hideSelf: -> @trigger "controlsView:hide"

    # ESC hides the controls widget
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

