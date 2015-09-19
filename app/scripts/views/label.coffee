define [
  './base'
  './../templates/label'
], (BaseView, labelTemplate) ->

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
          position: @myTooltipPosition

    refreshTooltip: (tooltip) ->
      @$('label.dative-tooltip')
        .tooltip
          content: tooltip
          position: @myTooltipPosition

    myTooltipPosition:
      my: "right-300 top"
      at: 'right top'
      collision: 'flipfit'


