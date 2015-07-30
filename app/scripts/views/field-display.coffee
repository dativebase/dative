define [
  './field'
  './label'
  './value-representation'
  './../utils/globals'
  './../utils/tooltips'
  './../templates/field-display'
], (FieldView, LabelView, ValueRepresentationView, globals, tooltips,
  fieldDisplayTemplate) ->

  # Field Display View
  # ------------------
  #
  # A base class view for views that display a label and a representation for a
  # single field (or attribute) of a model.
  # NOTE: assumes that the `@model` is a form model.
  #
  # Example usage:
  #
  #   syntaxFieldDisplayView = new FieldDisplayView
  #     attribute: 'syntacticTreeLatex'
  #     model: @myFormModelInstance
  #
  # The default behaviour is to display a `LabelView` instance and a
  # `ValueRepresentationView` instance.
  #
  # The object passed to the constructor of a `FieldView` instance (or subclass
  # thereof) must minimally have an `attribute` key. The HTML attribute values
  # (class, value, title, name, etc.) are all generated from this `attribute`
  # value (given certain assumptions about the data structure and notational
  # conventions of FieldDB and OLD datums/forms.

  class FieldDisplayView extends FieldView

    # Override this in a subclass to swap in a new representation view.
    getRepresentationView: ->
      new ValueRepresentationView @context

    # Override this in a subclass to swap in a new label view.
    getLabelView: ->
      new LabelView @context

    # Override this in a subclass to provide non-standard contextual attributes.
    getContext: ->
      attribute: @attribute
      options: @options
      model: @model
      name: @getName()
      class: @getClass()
      title: @getTooltip()
      value: @getValue()
      label: @getLabel()
      fieldDisplayLabelContainerClass: @fieldDisplayLabelContainerClass
      fieldDisplayRepresentationContainerClass:
        @fieldDisplayRepresentationContainerClass

    fieldDisplayLabelContainerClass: 'dative-field-display-label-container'
    fieldDisplayRepresentationContainerClass:
      'dative-field-display-representation-container'

    # Return an array of model attributes that this field display "governs".
    # This defaults to `[@attribute]` but for field display views that govern
    # multiple attributes, this should be overridden.
    governedAttributes: -> [@attribute]

    guify: ->

    template: fieldDisplayTemplate
    tagName: 'div'
    className: 'dative-field-display'

    initialize: (options) ->
      @resource = options.resource or 'forms'
      @tooltipIsRefreshable = options.tooltipIsRefreshable or false
      @attribute = options.attribute
      @activeServerType = @getActiveServerType()
      @context = @getContext()
      @labelView = @getLabelView()
      @representationView = @getRepresentationView()

    render: ->
      @$el.html @template(@context)
      @visibility()
      @labelView.setElement @$('.dative-field-display-label-container')
      @representationView.setElement @$('.dative-field-display-representation-container')
      @renderLabelView()
      @renderRepresentationView()
      @guify()
      @listenToEvents()
      @

    listenToEvents: ->
      @stopAndRelisten()
      @listenTo @model, 'change', @refresh

    # Refresh the field display: essentially, make the display reflect the
    # model state.
    # NOTE/TODO @jrwdunham: it is inefficient to refresh EVERY field display on
    # every model change; however, because nearly all FieldDB datum attributes
    # are associated to a single model attribute (i.e., `datumFields`),
    # detecting exactly which field displays should be refreshed is not simple.
    refresh: ->
      @context = @getContext()
      @representationView.refresh @context
      @renderRepresentationView()
      @visibility()

    visibility: ->
      if @shouldBeHidden()
        @$el.hide()
      else
        @$el.show()

    renderLabelView: ->
      @labelView.render()
      @rendered @labelView

    renderRepresentationView: ->
      @representationView.render()
      @rendered @representationView

    # Return an in-line CSS style to hide the HTML of an empty form attribute
    # Note the use of `=>` so that the ECO template knows to use this view's
    # context.
    shouldBeHidden: ->
      value = @context.value
      if _.isDate(value) or _.isNumber(value) or _.isBoolean(value)
        false
      else if _.isEmpty(value) or @isValueless(value)
        true
      else
        false

    # Returns `true` only if thing is an object all of whose values are either
    # `null` or empty strings.
    isValueless: (thing) ->
      _.isObject(thing) and
      (not _.isArray(thing)) and
      _.isEmpty(_.filter(_.values(thing), (x) -> x isnt null and x isnt ''))

