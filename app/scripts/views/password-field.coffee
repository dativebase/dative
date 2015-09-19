define [
  './field'
  './password-input'
], (FieldView, PasswordInputView) ->

  # Password Field View
  # -------------------
  #
  # A view for a data input field that is an input[type=password] (with a label
  # and validation machinery, as inherited from FieldView.)
  #
  # Note: this view is intended to be used in tandem with a password confirm
  # field view that is an instance of this class but which has `@confirmField`
  # set to `true`. These two views will trigger events such that value changes
  # in either one will correctly alter any validation errors on the other.

  class PasswordFieldView extends FieldView

    initialize: (options) ->
      super options
      @confirmField = options.confirmField or false

    getInputView: ->
      new PasswordInputView @context

    events:
      'input':                 'inputChanged' # fires when an input, textarea or date-picker changes
      'keydown .ms-container': 'multiselectKeydown'
      'keydown textarea, input, .ui-selectmenu-button, .ms-container':
                               'controlEnterSubmit'

    inputChanged: ->
      @setToModel()
      if @confirmField
        event = 'passwordSetToModel'
      else
        event = 'passwordConfirmSetToModel'
      @model.trigger event

    listenToEvents: ->
      super
      if @confirmField
        event = 'passwordConfirmSetToModel'
      else
        event = 'passwordSetToModel'
      @listenTo @model, event, @setToModel

