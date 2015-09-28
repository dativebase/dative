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

    selectmenuDefaultZIndex: 100

    # Make <select>s into jQuery selectmenus.
    # NOTE: the functions triggered by the open and close events are a hack so
    # that the menu data will be displayed in jQueryUI dialogs, which have a
    # higher z-index.
    selectmenuify: (width='auto', selectClass=null) ->
      selectClass = selectClass or @selectClass or null
      selector = if selectClass then "select.#{selectClass}" else 'select'
      @$(selector)
        .selectmenu
          width: width
          open: (event, ui) ->
            @selectmenuDefaultZIndex = $('.ui-selectmenu-open').first().zIndex()
            $('.ui-selectmenu-open').zIndex 120
          close: (event, ui) ->
            $('.ui-selectmenu-open').zIndex @selectmenuDefaultZIndex
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
      @disableTextInputs()
      @disableButtons()
      @disableSelectmenus()

    # Override this in an input-appropriate way, if necessary.
    enable: ->
      @enableTextareas()
      @enableTextInputs()
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

    disableTextInputs: ->
      @$('input[type=text]')
        .prop 'disabled', true
        .addClass 'ui-state-disabled'

    enableTextInputs: ->
      @$('input[type=text]')
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

