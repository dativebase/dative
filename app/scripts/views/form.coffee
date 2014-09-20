define [
  'backbone'
  './base'
], (Backbone, BaseView) ->

  # Form View
  # ---------
  #
  # For displaying individual forms with an IGT interface.
  #
  # TODOS
  # 1. change all of the 'old-' stuff to 'dative-' or '' (in base.css and in templates)
  # 2. change all of the snake_case to camelCase, as needed
  # 3. make dates human-readable (see `getHumanReadable` in OLD.js)
  # 4. render the file view into the form view ... (cf. `filesDiv.append(filesContent);` of OLD.js)

  class FormView extends BaseView

    template: JST['app/scripts/templates/form.ejs']
    tagName: 'div'
    className: 'igt-form old-form-object ui-corner-all'
    #tagName: 'table'
    #className: 'dative-pagin-item'

    initialize: () ->
      @listenTo @model, 'change', @render
      @listenTo Backbone, 'formViews:dehighlight', @_dehighlight

    events:
      'click': '_highlightAndShow'
      'click .form-hide-button': '_clickHideButton'

    render: ->
      console.log @model.toJSON()
      @$el.attr('id', @model.cid).html @template(@model.toJSON())
      @_guify()
      this

    _guify: ->
      @$('.form-hide-button').button(
        icons: primary: 'ui-icon-close'
        text: false).hide()
      @$('.form-buttons').buttonset().hide()
      @$('.form-secondary-data').hide()

    _highlightAndShow: ->
      console.log 'in _highlightAndShow'
      @_highlight()
      @_showAdditionalData()

    _highlight: ->
      Backbone.trigger 'formViews:dehighlight'
      @$el.addClass 'ui-state-highlight'

    _dehighlight: ->
      @$el.removeClass 'ui-state-highlight'

    _clickHideButton: (event) ->
      event.stopPropagation()
      @_hideAdditionalData()

    # Show and hide the additional data div, class is 'secondary-data' I think
    _showAdditionalData: ->
      @$el.animate('border-color': FormView.jQueryUIColors.defBo, 'slow')
      @$('.form-buttons, .form-secondary-data, .form-hide-button')
        .slideDown 'slow'

    _hideAdditionalData: (event) ->
      @$el.css 'border-color': 'transparent'
      @$('.old-form-buttons, .old-form-secondary-data, .old-form-hide-button')
        .slideUp 'slow'

