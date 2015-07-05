define [
  './field'
  './search-input'
], (FieldView, SearchInputView) ->

  # Search Field View
  # -------------------
  #
  # A view for a data input field that is a search, i.e., a JSON object
  # encoding a search expression using the OLD search format.

  class SearchFieldView extends FieldView

    targetResourceName: 'form'

    getFieldLabelContainerClass: ->
      "#{super} top"

    getFieldInputContainerClass: ->
      "#{super} full-width"

    getInputView: ->
      @context.targetResourceName = @targetResourceName
      new SearchInputView @context

    setToModel: ->
      super
      @model.trigger 'change'

    # Set the state of this field to the model.
    setToModelSuper: ->
      domValue = @getValueFromDOM()
      switch @activeServerType
        when 'FieldDB' then @model.setDatumValueSmart domValue
        when 'OLD' then @model.set domValue
      if @submitAttempted then @validate()

    # We override the default `FieldView` events because we don't want to call
    # `setToModel` whenever an input changes. Instead, we listen for a special
    # event on the `SearchInputView` to know when the search has changed in
    # response to user actions.
    events:
      'keydown textarea, input, .ui-selectmenu-button, .ms-container':
        'controlEnterSubmit'

