define [
  'backbone'
  './base'
  'autosize'
], (Backbone, BaseView) ->

  # Input View
  # ----------
  #
  # A base class for views over inputs (i.e., <select>s, <input>s, etc.).

  class InputView extends BaseView

    initialize: (@context) ->

    render: ->
      @$el.html @template(@context)
      @bordercolorify()
      @autosize()
      @

    autosize: -> @$('textarea').autosize append: false

    # Make <select>s into jQuery selectmenus.
    selectmenuify: (width='auto', selectClass=null) ->
      selectClass = selectClass or @selectClass or null
      selector = if selectClass then "select.#{selectClass}" else 'select'
      @$(selector)
        .selectmenu width: width
        .each (index, element) =>
          @transferClassAndTitle @$(element) # so we can tooltipify the selectmenu

    buttonify: -> @$('button').button()

    # Make the border colors match the jQueryUI theme.
    bordercolorify: ->
      @$('textarea').css "border-color", @constructor.jQueryUIColors().defBo

