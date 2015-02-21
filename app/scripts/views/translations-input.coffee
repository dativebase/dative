define [
  'backbone'
  './field'
  './select-textarea-button-input'
], (Backbone, FieldView, SelectTextareaButtonInputView) ->

  # Translations Input View
  # -----------------------
  #
  # A view for a *set* of input field sets for modifying an array of translation
  # objects. That is, something like:
  #
  #   [
  #     {
  #       transcription: 'dog',
  #       grammaticality: ''
  #     },
  #     {
  #       transcription: 'wolf',
  #       grammaticality: '*'
  #     }
  #   ]
  #
  # The value of `@context.value` (where @context is the object passed to the
  # constructor) is an array like that shown above. Each object in the value
  # array gets its own input view: a `SelectTextareaButtonInputView` instance.
  #
  # When the <button> of one of the rendered input sub-views is clicked, this
  # view is responsible for removing the sub-view or adding a new one, as
  # appropriate.

  class TranslationsInputView extends FieldView

    initialize: (@context) ->
      @attribute = @context.attribute
      @selectAttribute = @context.translationSelectAttribute
      @textareaAttribute = @context.translationTextareaAttribute
      @activeServerType = @getActiveServerType()
      @translationInputViews = {}
      @getTranslationInputViews()

    # Add translation-specific input views to `@translationInputViews`
    getTranslationInputViews: ->
      if @context.value.length is 0
        @pushTranslationInputView 0
      else
        for translation, index in @context.value
          @pushTranslationInputView index, translation

    # Create a view instance for a translation object, add it to
    # `@translationInputViews`, and return the view instance.
    # Note that this is not really "pushing" to an array: I'm treating the
    # `@translationInputViews` object as an array: it's an object with
    # stringified numbers as keys. I do this because any input view may be
    # destroyed yet the indices need to be maintained.
    pushTranslationInputView: (index, translationObject=null) ->
      translationObject = translationObject or @getDefaultTranslationObject()
      inputSetContext = @getInputSetContext index, translationObject
      inputSetView = new SelectTextareaButtonInputView inputSetContext
      inputSetView.index = index
      @translationInputViews[index] = inputSetView
      inputSetView

    # Remove the translation input set view from the DOM and destroy it.
    removeInputSetView: (index) ->
      translationView = @translationInputViews[index]
      translationView.$el.slideUp
        complete: =>
          translationView.close()
          translationView.$el
            .prev()
            .find('button').focus()
          translationView.$el.remove()
          delete @translationInputViews[index]

    # Append a new `SelectTextareaButtonInputView` instance's HTML to the DOM.
    # This is called when the "+" button is clicked.
    appendNewInputSetView: ->
      newIndex = @getNextIndex()
      newInputSetView = @pushTranslationInputView newIndex
      @renderInputSetView newInputSetView, true
      @listenToInputSetView newInputSetView
      @focusLastInputSetView()

    focusLastInputSetView: ->
      @$('.dative-field-subinput-container').last().find('textarea').focus()

    # Get the next index for an input view: basically increment the highest
    # existing index.
    getNextIndex: ->
      try
        indices = _.map(_.keys(@translationInputViews), (x) -> Number(x)).sort()
        [..., highestIndex] = indices
        if isNaN highestIndex
          0
        else
          highestIndex + 1
      catch
        0

    # An empty translation object.
    getDefaultTranslationObject: ->
      defaultTranslationObject = {}
      defaultTranslationObject[@context.translationSelectAttribute] = ''
      defaultTranslationObject[@context.translationTextareaAttribute] = ''
      defaultTranslationObject

    # The object returned by this method is passed to each input view on
    # initialization.
    getInputSetContext: (index, translationObject) ->
      tmp =
        index:             index

        selectAttribute:   @selectAttribute
        selectName:        @getArrayItemAttributeName @attribute, index, @selectAttribute
        selectClass:       @getClass @selectAttribute
        selectTitle:       @getTooltip "#{@attribute}.#{@selectAttribute}"
        selectValue:       translationObject[@selectAttribute]

        textareaAttribute: @textareaAttribute
        textareaName:      @getName @textareaAttribute
        textareaName:      @getArrayItemAttributeName @attribute, index, @textareaAttribute

        textareaClass:     @getClass @textareaAttribute
        textareaTitle:     @getTooltip "#{@attribute}.#{@textareaAttribute}"
        textareaValue:     translationObject[@textareaAttribute]

        buttonClass:       @getButtonClass index
        buttonTitle:       @getButtonTitle index
        buttonIconClass:   @getButtonIconClass index
      _.extend {}, @context, tmp

    render: ->
      for index, inputSetView of @translationInputViews
        @renderInputSetView inputSetView
      @listenToEvents()

    # Render an input set view; setting `animate` to true will cause `slideDown`.
    renderInputSetView: (inputSetView, animate=false) ->
      @$el.append inputSetView.render().el
      @rendered inputSetView
      if animate
        inputSetView.render().$el
          .hide()
          .slideDown()

    listenToEvents: ->
      super
      for index, inputSetView of @translationInputViews
        @listenToInputSetView inputSetView

    listenToInputSetView: (inputSetView) ->
      @listenTo inputSetView, 'remove', @removeInputSetView
      @listenTo inputSetView, 'new', @appendNewInputSetView

    # The first tranlation input set has a "+" button, the rest have "-" buttons.
    getButtonClass: (index) -> if index is 0 then 'new' else 'remove'

    getButtonTitle: (index) ->
      if index is 0
        "add another #{@utils.singularize @context.attribute}"
      else
        "remove this #{@utils.singularize @context.attribute}"

    # Font awesome icon class for the new/remove button.
    getButtonIconClass: (index) -> if index is 0 then 'fa-plus' else 'fa-minus'

