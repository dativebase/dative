define [
  './base'
  './../utils/globals'
  './../templates/button-control'
], (BaseView, globals, buttonControlTemplate) ->

  # Serve Compiled Control View
  # ---------------------------
  #
  # View for a control for requesting that a phonology resource return its
  # compiled file representation.

  class ServeCompiledControlView extends BaseView

    template: buttonControlTemplate
    className: 'serve-compiled-control-view control-view dative-widget-center'

    initialize: (options) ->
      @activeServerType = @getActiveServerType()
      @listenToEvents()
      @resourceName = options.resourceName or 'phonology'

    events:
      'click button.serve-compiled':         'serveCompiled'

    listenToEvents: ->
      super
      @listenTo @model, "serveCompiledStart", @serveCompiledStart
      @listenTo @model, "serveCompiledEnd", @serveCompiledEnd
      @listenTo @model, "serveCompiledFail", @serveCompiledFail
      @listenTo @model, "serveCompiledSuccess", @serveCompiledSuccess

    # Write the initial HTML to the page.
    html: ->
      context =
        buttonClass: 'serve-compiled'
        buttonTitle: "Clicking this button will cause the binary file that
          represents the compiled phonology to be downloaded from the server."
        buttonText: 'Serve Compiled'
        actionResultsClass: 'serve-compiled-results'
      @$el.html @template(context)

    render: ->
      @html()
      @guify()
      @listenToEvents()
      @

    guify: ->
      @buttonify()
      @tooltipify()

    tooltipify: ->
      @$('.dative-tooltip')
        .tooltip position: @tooltipPositionLeft('-20')

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

    ############################################################################
    # Serve Compiled
    ############################################################################

    serveCompiled: ->
      @model.serveCompiled()

    serveCompiledStart: ->
      @spin 'button.serve-compiled', '50%', '135%'
      @disableServeCompiledButton()

    serveCompiledEnd: ->
      @stopSpin 'button.serve-compiled'
      @enableServeCompiledButton()

    serveCompiledFail: (error) ->
      Backbone.trigger "#{@resourceName}ServeCompiledFail", error, @model.get('id')

    serveCompiledSuccess: ->
      Backbone.trigger "#{@resourceName}ServeCompiledSuccess", @model.get('id')

    disableServeCompiledButton: ->
      @$('button.serve-compiled').button 'disable'

    enableServeCompiledButton: ->
      @$('button.serve-compiled').button 'enable'



