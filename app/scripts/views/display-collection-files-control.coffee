define [
  './base'
  './../utils/globals'
  './../templates/button-control'
], (BaseView, globals, buttonControlTemplate) ->

  # Display Collection Files Control View
  # -------------------------------------
  #
  # View for a control that is a button that, when clicked, causes the
  # references to files in the HTML value of a collection (already converted to
  # <div>s with data-id attributes) into FileView representations.
  #
  # Note: all of the work here is actually done by the CollectionView. These
  # controls should probably not be in the canonical controls interface.
  # Instead, the HTML field display view should handle this. The reason I chose
  # the current approach is because the CSS was getting really complicated,
  # i.e., to put control machinery within a field display view.

  class DisplayCollectionFilesControlView extends BaseView

    template: buttonControlTemplate
    className: 'display-collection-files-control-view control-view
      dative-widget-center'

    initialize: (options) ->
      @activeServerType = @getActiveServerType()
      @listenToEvents()

    events:
      'click button.display-collection-files': 'tellSuperviewToDisplayReferencedFiles'

    listenToEvents: ->
      super
      @listenTo @model, "returningReferencedFileIds", @displayReferencedFiles

    controlSummaryClass: 'display-collection-files-summary'
    controlResultsClass: 'display-collection-files-results'
    controlResults: ''
    getControlSummary: -> ''

    buttonClass: 'display-collection-files'

    html: ->
      context =
        buttonClass: @buttonClass
        buttonTitle: "Click this button to transform the references to files in
          the “html” value into standard Dative-style file displays."
        buttonText: 'Display referenced files'
        controlResultsClass: @controlResultsClass
        controlSummaryClass: @controlSummaryClass
        controlResults: @controlResults
        controlSummary: @getControlSummary()
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

    tellSuperviewToDisplayReferencedFiles: ->
      @model.trigger 'displayReferencedFiles'

    disableDisplayButton: ->
      @$("button.#{@buttonClass}").button 'disable'

    enableDisplayButton: ->
      @$("button.#{@buttonClass}").button 'enable'


