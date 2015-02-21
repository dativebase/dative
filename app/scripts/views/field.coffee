define [
  'backbone'
  './form-handler-base'
  './label'
  './textarea-input'
  './../utils/globals'
  './../utils/tooltips'
  './../templates/field'
], (Backbone, FormHandlerBaseView, LabelView, TextareaInputView, globals, tooltips,
  fieldTemplate) ->

  # Field View
  # ----------
  #
  # A base class view for data input fields for a single attribute of a model:
  # basically a label and one or more input controls. NOTE: assumes that the
  # `@model` is a form model.
  #
  # Example usage:
  #
  #   syntaxFieldView = new FieldView
  #     attribute: 'syntacticTreeLatex'
  #     model: @myFormModelInstance
  #
  # The DOM real estate controlled by this type of view is typically an <li>
  # with a <label> and an input (e.g., <input type="text">, <select> or
  # <textarea>) that is used to modify/create a value for a single form
  # attribute, e.g., `transcription`, `utterance`, `translations`, etc.
  #
  # The default behaviour is to display a LabelView instance and a
  # TextareaInputView instance.
  #
  # The object passed to the constructor of a `FieldView` instance (or subclass
  # thereof) must minimally have an `attribute` key. The HTML attribute values
  # are generated from this `attribute` value.
  #
  # Any method may be overridden in sub-classes. The helper methods used to
  # generate the context object for templates constitute the bulk of the
  # re-usable code here. See `getName`, `getValue`, `getTooltip`, etc. below.

  class FieldView extends FormHandlerBaseView

    # Override this in a subclass to swap in a new input view, e.g., one based
    # on a <select> or an <input[type=text]>, etc.
    getInputView: ->
      new TextareaInputView @context

    # Override this in a subclass to swap in a new label view.
    getLabelView: ->
      new LabelView @context

    # Override this in a subclass to provide non-standard contextual attributes.
    # Input views expect a context object to be passed to their constructors,
    # which they will in turn pass to their templates.
    getContext: ->
      attribute: @attribute
      options: @options
      model: @model
      name: @getName()
      class: @getClass()
      title: @getTooltip()
      value: @getValue()
      label: @getLabel()

    guify: ->

    template: fieldTemplate
    tagName: 'li'
    className: 'dative-form-field'

    initialize: (options) ->
      @attribute = options.attribute
      @activeServerType = @getActiveServerType()
      @options = options.options # possible values for forced-choice fields, e.g., `users` or `grammaticalities` with an OLD back-end.
      @context = @getContext()
      @labelView = @getLabelView()
      @inputView = @getInputView()

    events: {}

    render: ->
      @$el.html @template(@context)
      @renderLabelView()
      @renderInputView()
      @guify()
      @listenToEvents()
      @

    renderLabelView: ->
      @labelView.setElement @$('.dative-field-label-container')
      @labelView.render()
      @rendered @labelView

    renderInputView: ->
      @inputView.setElement @$('.dative-field-input-container')
      @inputView.render()
      @rendered @inputView

    ############################################################################
    # Helper methods for building a template context out of the form @model and
    # the supplied @attribute.
    ############################################################################

    # Value for the HTML name attribute of the input; just `attribute`. NOTE: I
    # don't know why I was previously converting this to hyphen-case...
    getName: (attribute=@attribute) ->
      #@hyphenCaseify attribute
      attribute

    # CSS class for the input; just `attribute` in hyphen-case.
    getClass: (attribute=@attribute) ->
      @hyphenCaseify attribute

    # Get `attribute` in hyphen-case.
    hyphenCaseify: (attribute) ->
      switch @activeServerType
        when 'FieldDB' then @utils.camel2hyphen attribute
        when 'OLD' then @utils.snake2hyphen attribute
        else 'default'

    # HTML label text; just `attribute` in regular case.
    # TODO: do something more intelligent by trying to get FieldDB datumField
    # human-friendly labels.
    getLabel: (attribute=@attribute) ->
      switch @activeServerType
        when 'FieldDB' then @utils.camel2regular attribute
        when 'OLD' then @utils.snake2regular attribute
        else 'default'

    # The tooltip (the HTML title attribute) for both the label and the input.
    getTooltip: (attribute=@attribute) ->
      switch @activeServerType
        when 'FieldDB' then @getFieldDBAttributeTooltip attribute
        when 'OLD' then @getOLDAttributeTooltip attribute
        else 'default'

    # The value to go in the input. See the form model for `getDatumValueSmart`.
    getValue: (attribute=@attribute) ->
      switch @activeServerType
        when 'FieldDB' then @model.getDatumValueSmart attribute
        when 'OLD' then @model.get attribute
        else ''

    # Return a `name` value for an input field that holds the value of an
    # object's `subattribute` where that object is element with index `index`
    # in an array identified by `attribute`. This is useful for arrays of
    # translations/comments, etc. Calling `getArrayItemAttributeName
    # 'translations', 0, 'transcription'` will produce
    # "translations-0.transcription".
    getArrayItemAttributeName: (attribute, index, subattribute) ->
      "#{attribute}-#{index}.#{subattribute}"

    # If `options.grammaticalities` is an array, return it with '' as its first
    # member and all other empty strings removed. Useful for grammaticality
    # <select>s for OLD apps where the '' grammatical value may be left
    # implicit. 
    addGrammaticalToGrammaticalities: (options) ->
      if options?.grammaticalities
        if @utils.type options.grammaticalities is 'array'
          tmp = (g for g in options.grammaticalities if g isnt '')
          options.grammaticalities = [''].concat tmp
      options

