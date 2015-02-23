define [
  'backbone'
  './field'
  './textarea-button-input'
], (Backbone, FieldView, TextareaButtonInputView) ->

  # Input Set View
  # --------------
  #
  # A view for a *set* of input field sets. This is used for form attributes
  # that are valuated as arrays, e.g., OLD translations or FieldDB comments.
  #
  # The value of `@context.value` (where @context is the object passed to the
  # constructor) is expected to be an array. Each object in the value array is
  # assigned its own input view.

  class InputSetView extends FieldView

    initialize: (@context) ->
      @attribute = @context.attribute
      @subattribute = @context.subattribute
      @activeServerType = @getActiveServerType()
      @inputViews = {}
      @getInputViews()

    # Inheriting from `FieldView` is good for re-using some methods, but we
    # don't want to doubly listen to events that `FieldView`-inheriting
    # super-view is already listening to.
    events: {}

    # Add input views to `@inputViews`, one for each object in `@context.value`.
    getInputViews: ->
      if @context.value.length is 0
        @pushInputView 0
      else
        for object, index in @context.value
          @pushInputView index, object

    # Override this in sub-classes in order to change the type of sub-input.
    getInputView: (inputContext) ->
      new TextareaButtonInputView inputContext

    # Create a view instance for an input object, add it to
    # `@inputViews`, and return the view instance.
    # Note that this is not really "pushing" to an array: I'm treating the
    # `@inputViews` object as an array: it's an object with
    # stringified numbers as keys. I do this because any input view may be
    # destroyed yet the indices need to be maintained.
    pushInputView: (index, object=null) ->
      object = object or @getDefaultObject()
      inputContext = @getInputContext index, object
      inputView = @getInputView inputContext
      inputView.index = index
      @inputViews[index] = inputView
      inputView

    # Remove the input set view with index = `index` from the DOM and destroy
    # it. This is called when the "x" button is clicked.
    removeInputView: (index) ->
      inputView = @inputViews[index]
      inputView.$el.slideUp
        complete: =>
          inputView.close()
          inputView.$el
            .prev()
            .find('button').focus()
          inputView.$el.remove()
          delete @inputViews[index]

    # Append a new input view instance's HTML to the DOM.
    # This is called when the "+" button is clicked.
    appendNewInputView: ->
      newIndex = @getNextIndex()
      newInputView = @pushInputView newIndex
      @renderInputView newInputView, true
      @listenToInputView newInputView
      @focusLastInputView()

    focusLastInputView: ->
      @$('.dative-field-subinput-container').last().find('textarea').focus()

    # Get the next index for an input view: basically increment the highest
    # existing index.
    getNextIndex: ->
      try
        indices = _.map(_.keys(@inputViews), (x) -> Number(x)).sort()
        [..., highestIndex] = indices
        if isNaN highestIndex
          0
        else
          highestIndex + 1
      catch
        0

    # An empty object, to be pushed to the array that represents the value of
    # this input set.
    getDefaultObject: ->
      defaultObject = {}
      defaultObject[@subattribute] = ''
      defaultObject

    # The object returned by this method is passed to each input view on
    # initialization.
    getInputContext: (index, object) ->
      tmp =
        index:             index
        attribute:         @attribute
        subattribute:      @subattribute
        subattributeName:  @getArrayItemAttributeName @attribute, index, @subattribute
        subattributeClass: @getClass @subattribute
        subattributeTitle: @getTooltip "#{@attribute}.#{@subattribute}"
        subattributeValue: object[@subattribute]
        buttonClass:       @getButtonClass index
        buttonTitle:       @getButtonTitle index
        buttonIconClass:  @getButtonIconClass index
      _.extend {}, @context, tmp

    render: ->
      for index, inputView of @inputViews
        @renderInputView inputView
      @listenToEvents()

    # Render an input set view; setting `animate` to true will cause `slideDown`.
    renderInputView: (inputView, animate=false) ->
      @$el.append inputView.render().el
      @rendered inputView
      if animate
        inputView.render().$el
          .hide()
          .slideDown()

    listenToEvents: ->
      super
      for index, inputView of @inputViews
        @listenToInputView inputView

    listenToInputView: (inputView) ->
      @listenTo inputView, 'remove', @removeInputView
      @listenTo inputView, 'new', @appendNewInputView

    # The first input has a "+" button, the rest have "-" buttons.
    getButtonClass: (index) -> if index is 0 then 'new' else 'remove'

    getButtonTitle: (index) ->
      if index is 0
        "add another #{@utils.singularize @context.attribute}"
      else
        "remove this #{@utils.singularize @context.attribute}"

    # Font awesome icon class for the new/remove button.
    getButtonIconClass: (index) -> if index is 0 then 'fa-plus' else 'fa-times'

    # Return a `name` value for an input field that holds the value of an
    # object's `subattribute` where that object is element with index `index`
    # in an array identified by `attribute`. This is useful for arrays of
    # translations/comments, etc. Calling `getArrayItemAttributeName
    # 'translations', 0, 'transcription'` will produce
    # "translations-0.transcription".
    getArrayItemAttributeName: (attribute, index, subattribute) ->
      "#{attribute}-#{index}.#{subattribute}"

    # Get value from DOM.
    # This method first extracts from the input fields an object with
    # hyphen-dot-notation names; e.g.:
    #
    #   { translations-0.grammaticality: "",
    #     translations-0.transcription: "dog",
    #     translations-1.grammaticality: "*",
    #     translations-1.transcription: "hound" }
    #
    # From the above, it returns something like:
    #
    #   { translations: [
    #     { grammaticality: "", transcription: "dog" },
    #     { grammaticality: "*", transcription: "hound" }]}
    #
    getValueFromDOM: (requiredAttribute=null) ->
      result = {}
      interimResult = {}
      arrayOfObjects = (val.getValueFromDOM() for key, val of @inputViews)
      object = @arrayOfObjectsToObject arrayOfObjects
      for complexName, value of object
        [attribute, tmp] = complexName.split '-'
        [index, subattribute] = tmp.split '.'
        if attribute of interimResult
          subobject = interimResult[attribute]
        else
          subobject = interimResult[attribute] = {}
        if not (index of subobject)
          subobject[index] = {}
        subobject[index][subattribute] = value

      # At this point, `interimResult` should be something like:
      #   { translations: {
      #     "0": { "grammaticality": "", "transcription": "dog" },
      #     "1": { "grammaticality": "*", "transcription": "hound" }}}
      #
      array = result[attribute] = []
      for indexKey in _.keys(interimResult[attribute]).sort()
        objectValue = interimResult[attribute][indexKey]
        if requiredAttribute
          if objectValue[requiredAttribute] then array.push objectValue
        else
          array.push objectValue
      result
