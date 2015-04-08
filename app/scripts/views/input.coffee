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
      @listenToEvents()
      @

    refresh: (@context) ->
      @render()

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

    # Override this in an input-appropriate way, if necessary.
    disable: ->
      @disableTextareas()
      @disableButtons()
      @disableSelectmenus()

    # Override this in an input-appropriate way, if necessary.
    enable: ->
      @enableTextareas()
      @enableButtons()
      @enableSelectmenus()

    disableTextareas: ->
      @$('textarea')
        .prop 'disabled', true
        .addClass 'ui-state-disabled'

    enableTextareas: ->
      @$('textarea')
        .prop 'disabled', false
        .removeClass 'ui-state-disabled'

    disableInputs: ->
      @$('input')
        .prop 'disabled', true
        .addClass 'ui-state-disabled'

    enableInputs: ->
      @$('input')
        .prop 'disabled', false
        .removeClass 'ui-state-disabled'

    disableButtons: -> @$('button').button 'disable'

    enableButtons: -> @$('button').button 'enable'

    disableSelectmenus: ->
      @$('select').each (index, element) =>
        $element = @$ element
        if $element.selectmenu 'instance'
          $element.selectmenu 'disable'

    enableSelectmenus: ->
      @$('select').each (index, element) =>
        $element = @$ element
        if $element.selectmenu 'instance'
          $element.selectmenu 'enable'

    disableMultiSelects: ->
      @$('select')
        .prop 'disabled', true
        .multiSelect 'refresh'

    enableMultiSelects: ->
      @$('select')
        .prop 'disabled', false
        .multiSelect 'refresh'

