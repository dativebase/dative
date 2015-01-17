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

    listenToEvents: ->
      @stopListening()
      @undelegateEvents()
      @delegateEvents()
      @listenTo @model, 'change', @render
      @listenTo Backbone, 'form:dehighlightAllFormViews', @dehighlight
      @listenTo Backbone, 'formsView:expandAllForms', @expand
      @listenTo Backbone, 'formsView:collapseAllForms', @collapse

    events:
      'click': 'highlightAndShowOnlyMe'
      'click .toggle-form-details': 'clickHideButton'

    render: ->
      @$el.attr('id', @model.cid).html @template(@model.toJSON())
      @guify()
      @listenToEvents()
      @

    guify: ->
      @guifyButtons()
      @hideHeader()
      @hideSecondaryData()

    guifyButtons: ->

      @$('button.toggle-form-details')
        .button()
        .tooltip
          position:
            my: "right-40 center"
            at: "left center"
            collision: "flipfit"

      @$('button.update-form')
        .button()
        .tooltip
          position:
            my: "right-40 center"
            at: "left center"
            collision: "flipfit"

      @$('button.associate-form')
        .button()
        .tooltip
          position:
            my: "right-40 center"
            at: "left center"
            collision: "flipfit"

      @$('button.export-form')
        .button()
        .tooltip
          position:
            my: "right-40 center"
            at: "left center"
            collision: "flipfit"

      @$('button.remember-form')
        .button()
        .tooltip
          position:
            my: "right-40 center"
            at: "left center"
            collision: "flipfit"

      @$('button.delete-form')
        .button()
        .tooltip
          position:
            my: "right-40 center"
            at: "left center"
            collision: "flipfit"

      @$('button.duplicate-form')
        .button()
        .tooltip
          position:
            my: "right-40 center"
            at: "left center"
            collision: "flipfit"

      @$('button.form-history')
        .button()
        .tooltip
          position:
            my: "right-40 center"
            at: "left center"
            collision: "flipfit"

    expand: ->
      @showFullAnimate()

    collapse: ->
      @hideFullAnimate()

    highlightAndShow: ->
      @highlight()
      @showSecondaryData()

    highlightAndShowOnlyMe: ->
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

    clickHideButton: (event) ->
      @stopEvent event
      @hideSecondaryData()

    ############################################################################
    # Hide & Show stuff
    ############################################################################

    # Full = border, header & secondary data
    ############################################################################

    showFull: ->
      @addBorder()
      @showHeader()
      @showSecondaryData()

    hideFull: ->
      @removeBorder()
      @hideHeader()
      @hideSecondaryData()

    showFullAnimate: ->
      @addBorderAnimate()
      @showHeaderAnimate()
      @showSecondaryDataAnimate()

    hideFullAnimate: ->
      @removeBorderAnimate()
      @hideHeaderAnimate()
      @hideSecondaryDataAnimate()

    # Header
    ############################################################################

    showHeader: ->
      @$('.dative-widget-header').first().show()

    hideHeader: ->
      @$('.dative-widget-header').first().hide()

    showHeaderAnimate: ->
      @$('.dative-widget-header').first().slideDown 'slow'

    hideHeaderAnimate: ->
      @$('.dative-widget-header').first().slideUp 'slow'

    # Secondary Data
    ############################################################################

    showSecondaryData: ->
      @addBorder()
      @$('.form-secondary-data').show()

    hideSecondaryData: ->
      @removeBorder()
      @$('.form-secondary-data').hide()

    showSecondaryDataAnimate: ->
      @addBorderAnimate()
      @$('.form-secondary-data').slideDown 'slow'

    hideSecondaryDataAnimate: (event) ->
      @removeBorderAnimate()
      @$('.form-secondary-data').slideUp 'slow'

    # Border
    ############################################################################

    addBorder: ->
      @$el.css 'border-color': @constructor.jQueryUIColors().defBo

    removeBorder: ->
      @$el.css 'border-color': 'transparent'

    addBorderAnimate: ->
      @$el.animate 'border-color': @constructor.jQueryUIColors().defBo, 'slow'

    removeBorderAnimate: ->
      @$el.animate 'border-color': 'transparent', 'slow'

