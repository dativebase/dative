define [
  'backbone'
  './base'
  './../templates/form'
], (Backbone, BaseView, formTemplate) ->

  # Form View
  # ---------
  #
  # For displaying individual forms with an IGT interface.
  #
  # TODOS
  #
  # 1. make dates human-readable (see `getHumanReadable` in OLD.js)
  # 2. render the file view into the form view ... (cf. `filesDiv.append(filesContent);` of OLD.js)

  class FormView extends BaseView

    template: formTemplate
    tagName: 'div'
    className: ['dative-form-widget dative-widget-center ui-widget',
      'ui-widget-content ui-corner-all'].join ' '

    initialize: ->
      @secondaryDataVisible = false
      @headerVisible = false

    listenToEvents: ->
      @stopListening()
      @undelegateEvents()
      @delegateEvents()
      @listenTo @model, 'change', @render
      @listenTo Backbone, 'form:dehighlightAllFormViews', @dehighlight
      @listenTo Backbone, 'formsView:expandAllForms', @expand
      @listenTo Backbone, 'formsView:collapseAllForms', @collapse

    events:
      'click .form-primary-data': 'showAndHighlightOnlyMe'
      'mouseenter .form-primary-data': 'mouseenterPrimaryData'
      'mouseleave .form-primary-data': 'mouseleavePrimaryData'
      'click .toggle-form-details': 'hideFullAnimate'
      'click .toggle-secondary-data': 'toggleSecondaryDataAnimate'

    render: ->
      @html()
      @guify()
      @listenToEvents()
      @

    html: ->
      context = @getContext()
      @$el
        .attr 'id', @model.cid
        .html @template(context)

    # Context object for the template.
    getContext: ->
      context = _.extend(@model.toJSON(), {
        displayNoneStyle: @displayNoneStyle
        timeSince: @utils.timeSince
        humanDatetime: @utils.humanDatetime
        humanDate: @utils.humanDate
      })
      context.datetimeEntered = @utils.dateString2object(
        context.datetimeEntered)
      context.datetimeModified = @utils.dateString2object(
        context.datetimeModified)
      context.dateElicited = @utils.dateString2object(context.dateElicited)
      context

    # Return an in-line CSS style to hide the HTML of an empty form attribute
    displayNoneStyle: (attribute, context) =>
      value = context[attribute]
      if not _.isDate(value) and (_.isEmpty(value) or @isValueless(value))
        ' style="display: none;" '
      else
        ''

    # Returns `true` only if thing is an object all of whose values are `null`
    isValueless: (thing) ->
      _.isObject(thing) and
      (not _.isArray(thing)) and
      _.isEmpty(_.filter(_.values(thing), (x) -> x isnt null))

    guify: ->
      @guifyButtons()
      @tooltipify()
      if @headerVisible
        @showHeader()
        @turnOffPrimaryDataTooltip() 
      else
        @hideHeader()
        @turnOnPrimaryDataTooltip()
      if @secondaryDataVisible then @showSecondaryData() else @hideSecondaryData()

    tooltipify: ->
      @$('.form-secondary-data .dative-tooltip')
        .tooltip
          items: 'div'

    guifyButtons: ->

      @$('button.toggle-form-details')
        .button()
        .tooltip
          items: 'button'
          position:
            my: "right-10 center"
            at: "left center"
            collision: "flipfit"

      @$('button.toggle-secondary-data')
        .button()
        .tooltip
          position:
            my: "right-45 center"
            at: "left center"
            collision: "flipfit"

      @$('button.update-form')
        .button()
        .tooltip
          position:
            my: "left+220 center"
            at: "right center"
            collision: "flipfit"

      @$('button.associate-form')
        .button()
        .tooltip
          position:
            my: "left+185 center"
            at: "right center"
            collision: "flipfit"

      @$('button.export-form')
        .button()
        .tooltip
          position:
            my: "left+150 center"
            at: "right center"
            collision: "flipfit"

      @$('button.remember-form')
        .button()
        .tooltip
          position:
            my: "left+115 center"
            at: "right center"
            collision: "flipfit"

      @$('button.delete-form')
        .button()
        .tooltip
          position:
            my: "left+80 center"
            at: "right center"
            collision: "flipfit"

      @$('button.duplicate-form')
        .button()
        .tooltip
          position:
            my: "left+45 center"
            at: "right center"
            collision: "flipfit"

      @$('button.form-history')
        .button()
        .tooltip
          position:
            my: "left+10 center"
            at: "right center"
            collision: "flipfit"

    expand: ->
      @showFullAnimate()

    collapse: ->
      @hideFullAnimate()

    highlightAndShow: ->
      @highlight()
      @showSecondaryData()

    showAndHighlightOnlyMe: ->
      if not @headerVisible
        @showFullAnimate()
        @highlightOnlyMe()

    highlight: ->
      @$el.addClass 'ui-state-highlight'

    highlightOnlyMe: ->
      @dehighlightAll()
      @highlight()

    dehighlightAll: ->
      Backbone.trigger 'form:dehighlightAllFormViews'

    dehighlight: ->
      @$el.removeClass 'ui-state-highlight'

    dehighlightAndHide: ->
      @dehighlight()
      @hideSecondaryData()

    ############################################################################
    # Hide & Show stuff
    ############################################################################

    # Full = border, header & secondary data
    ############################################################################

    showFull: ->
      @addBorder()
      @turnOffPrimaryDataTooltip()
      @showHeader()
      @showSecondaryData()

    hideFull: ->
      @removeBorder()
      @turnOnPrimaryDataTooltip()
      @hideHeader()
      @hideSecondaryData()

    showFullAnimate: ->
      @addBorderAnimate()
      @turnOffPrimaryDataTooltip()
      @showHeaderAnimate()
      @showSecondaryDataAnimate()

    hideFullAnimate: ->
      @removeBorderAnimate()
      @turnOnPrimaryDataTooltip()
      @hideHeaderAnimate()
      @hideSecondaryDataAnimate()

    # Header
    ############################################################################

    showHeader: ->
      @headerVisible = true
      @$('.dative-widget-header').first().show()

    hideHeader: ->
      @headerVisible = false
      @$('.dative-widget-header').first().hide()

    showHeaderAnimate: ->
      @headerVisible = true
      @$('.dative-widget-header').first().slideDown()

    hideHeaderAnimate: ->
      @headerVisible = false
      @$('.dative-widget-header').first().slideUp()

    # Secondary Data
    ############################################################################

    showSecondaryData: ->
      @secondaryDataVisible = true
      @setSecondaryDataButtonStateOpen()
      @addBorder()
      @$('.form-secondary-data').show()

    hideSecondaryData: ->
      @secondaryDataVisible = false
      @setSecondaryDataButtonStateClosed()
      @removeBorder()
      @$('.form-secondary-data').hide()

    toggleSecondaryData: ->
      if @secondaryDataVisible
        @hideSecondaryData()
      else
        @showSecondaryData()

    showSecondaryDataAnimate: ->
      @secondaryDataVisible = true
      @setSecondaryDataButtonStateOpen()
      @addBorderAnimate()
      @$('.form-secondary-data').slideDown()

    hideSecondaryDataAnimate: (event) ->
      @secondaryDataVisible = false
      @setSecondaryDataButtonStateClosed()
      @removeBorderAnimate()
      @$('.form-secondary-data').slideUp()

    toggleSecondaryDataAnimate: ->
      if @secondaryDataVisible
        @hideSecondaryDataAnimate()
      else
        @showSecondaryDataAnimate()

    # Border
    ############################################################################

    addBorder: ->
      @$el.css 'border-color': @constructor.jQueryUIColors().defBo

    removeBorder: ->
      @$el.css 'border-color': 'transparent'

    addBorderAnimate: ->
      @$el.animate 'border-color': @constructor.jQueryUIColors().defBo

    removeBorderAnimate: ->
      @$el.animate 'border-color': 'transparent'

    setSecondaryDataButtonStateClosed: ->
      @$('.toggle-secondary-data')
        .find('i').removeClass('fa-angle-up').addClass('fa-angle-down').end()
        .button()
        .tooltip
          items: 'button'
          content: 'show the secondary data of this form'

    setSecondaryDataButtonStateOpen: ->
      @$('.toggle-secondary-data')
        .find('i').removeClass('fa-angle-down').addClass('fa-angle-up').end()
        .button()
        .tooltip
          items: 'button'
          content: 'hide the secondary data of this form'

    # Primary Data
    ############################################################################

    mouseenterPrimaryData: ->
      if not @headerVisible
        @$('.form-primary-data').css 'cursor', 'pointer'
      else
        @$('.form-primary-data').css 'cursor', 'text'

    mouseleavePrimaryData: ->
      if not @headerVisible
        @$('.form-primary-data').css 'cursor', 'text'

    turnOnPrimaryDataTooltip: ->
      $primaryDataDiv = @$('.form-primary-data').first()
      if not $primaryDataDiv.tooltip 'instance'
        $primaryDataDiv
          .tooltip
            open: (event, ui) -> ui.tooltip.css "max-width", "200px"
            items: 'div'
            content: ['Click here to reveal controls for, and more information',
              'about, this form.'].join ' '
            position:
              my: 'right-10 center'
              at: 'left center'
              collision: 'flipfit'

    turnOffPrimaryDataTooltip: ->
      $primaryDataDiv = @$('.form-primary-data').first()
      if $primaryDataDiv.tooltip 'instance'
        $primaryDataDiv.tooltip 'destroy'

