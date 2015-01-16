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
    className: 'igt-form dative-form-object ui-corner-all'

    listenToEvents: ->
      @stopListening()
      @undelegateEvents()
      @delegateEvents()
      @listenTo @model, 'change', @render
      @listenTo Backbone, 'form:dehighlightAllFormViews', @dehighlight
      @listenTo Backbone, 'formsView:expandAllForms', @expand
      @listenTo Backbone, 'formsView:collapseAllForms', @collapse

    events:
      'click': 'highlightAndShow'
      'click .form-hide-button': 'clickHideButton'

    render: ->
      @$el.attr('id', @model.cid).html @template(@model.toJSON())
      @guify()
      @listenToEvents()
      @

    guify: ->
      @$('.form-hide-button').button(
        icons: primary: 'ui-icon-close'
        text: false).hide()
      @$('.form-buttons').buttonset().hide()
      @$('.form-secondary-data').hide()

    expand: ->
      console.log 'A form view hears that you want to expand it.'

    collapse: ->
      console.log 'A form view hears that you want to collapse it.'

    highlightAndShow: ->
      @highlight()
      @showAdditionalData()

    highlight: ->
      Backbone.trigger 'form:dehighlightAllFormViews'
      @$el.addClass 'ui-state-highlight'

    dehighlight: ->
      @$el.removeClass 'ui-state-highlight'

    clickHideButton: (event) ->
      @stopEvent event
      @hideAdditionalData()

    # Show and hide the additional data div, class is 'secondary-data' I think
    showAdditionalData: ->
      @$el.animate 'border-color': FormView.jQueryUIColors.defBo, 'slow'
      @$('.form-buttons, .form-secondary-data, .form-hide-button')
        .slideDown 'slow'

    hideAdditionalData: (event) ->
      @$el.css 'border-color': 'transparent'
      @$('.dative-form-buttons, .dative-form-secondary-data, .dative-form-hide-button')
        .slideUp 'slow'

