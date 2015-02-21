define [
  'backbone'
  './form-handler-base'
  './../utils/globals'
  './../utils/tooltips'
  './../templates/textarea-field'
  'jqueryelastic'
], (Backbone, FormHandlerBaseView, globals, tooltips, textareaTemplate) ->

  # Textarea View
  # -------------
  #
  # A view for data input: a label, a textarea (and machinery for validation
  # feedback).

  class TextareaView extends FormHandlerBaseView

    template: textareaTemplate
    tagName: 'li'
    className: 'dative-form-field'

    initialize: (options) ->
      @attribute = options.attribute
      @activeServerType = @getActiveServerType()
      @visible = true

    listenToEvents: ->
      @stopListening()
      @undelegateEvents()
      @delegateEvents()

    events: {}

    render: ->
      @html()
      @listenToEvents()
      @guify()
      @

    html: ->
      context = @getContext()
      @$el.html @template(context)

    guify: ->
      @bordercolorify()
      @tooltipify()

    # Make the border colors match the jQueryUI theme.
    bordercolorify: ->
      @$('textarea')
        .css "border-color", @constructor.jQueryUIColors().defBo

    tooltipify: ->
      @$('textarea.dative-tooltip')
        .tooltip
          position:
            my: "right-200 top"
            at: 'left top'
            collision: 'flipfit'
      @$('label.dative-tooltip')
        .tooltip
          position:
            my: "right-10 top"
            at: 'left top'
            collision: 'flipfit'

    getContext: ->
      name: @getName()
      class: @getClass()
      title: @getTooltip()
      value: @getValue()
      label: @getLabel()

    # Textarea name
    getName: ->
      switch @activeServerType
        when 'FieldDB' then @utils.camel2hyphen @attribute
        when 'OLD' then @utils.snake2hyphen @attribute
        else 'default'

    # CSS class
    getClass: ->
      switch @activeServerType
        when 'FieldDB' then @utils.camel2hyphen @attribute
        when 'OLD' then @utils.snake2hyphen @attribute
        else 'default'

    # HTML label text
    getLabel: ->
      switch @activeServerType
        when 'FieldDB' then @utils.camel2regular @attribute
        when 'OLD' then @utils.snake2regular @attribute
        else 'default'

    # The tooltip (the HTML title attribute)
    getTooltip: ->
      switch @activeServerType
        when 'FieldDB' then @getFieldDBAttributeTooltip @attribute # TODO this without context param
        when 'OLD' then @getOLDAttributeTooltip @attribute
        else 'default'

    # The value to go in the textarea
    getValue: ->
      switch @activeServerType
        when 'FieldDB' then @model.getDatumValueSmart @attribute
        when 'OLD' then @model.get @attribute
        else ''

