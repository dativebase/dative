define [
  'backbone'
  './base'
  './../templates/label'
], (Backbone, BaseView, labelTemplate) ->

  # Label View
  # ----------
  #
  # A view for field labels; basically just a pluggable sub-view for HTML
  # <label>s.

  class LabelView extends BaseView

    template: labelTemplate

    initialize: (@context) ->

    render: ->
      @$el.html @template(@context)
      @tooltipify()
      @

    # Make title attrs into jQueryUI tooltips.
    tooltipify: ->
      @$('label.dative-tooltip')
        .tooltip
          position:
            my: "right-10 top"
            at: 'left top'
            collision: 'flipfit'

