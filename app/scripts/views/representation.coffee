define [
  './base'
  './../templates/value-representation'
], (BaseView, valueRepresentationTemplate) ->

  # Representation View
  # -------------------
  #
  # A base class for views over field representations. For example, a
  # transcription field may be represented as simply the text of the
  # transcription; a comments field, on the other hand, may have a more
  # complex representation since the value of a comments field may be
  # an array of objects and only some of the values of those objects'
  # attributes may be displayed.

  class RepresentationView extends BaseView

    initialize: (@context) ->

    valueFormatter: (value) -> value

    template: valueRepresentationTemplate

    render: ->
      @context.valueFormatter = @valueFormatter
      @$el.html @template(@context)
      @tooltipify()
      @

    refresh: (@context) ->

    # Make title attrs into jQueryUI tooltips.
    tooltipify: ->
      @$('div.dative-tooltip')
        .tooltip
          position: @tooltipPositionLeft '-200'

