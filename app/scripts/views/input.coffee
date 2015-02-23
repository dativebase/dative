define ['./base', 'autosize'], (BaseView) ->

  # Input View
  # ----------
  #
  # A base class for views over inputs (i.e., <select>s, <input>s, etc.).
  # Views that subclass `InputView` must minimally import a template and
  # set it to `@template`.

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
      @$('textarea, input')
        .css "border-color", @constructor.jQueryUIColors().defBo

    # Return an object (attributes are field names) representing the values in
    # the HTML inputs controlled by this input view.
    getValueFromDOM: ->
      @serializeObject @$(':input').serializeArray()

