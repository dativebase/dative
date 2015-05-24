define [
  './textarea-input'
], (TextareaInputView) ->

  # Search Input View
  # -----------------
  #
  # A view for a data input field that is a textarea for creating searches.

  class SearchInputView extends TextareaInputView

    initialize: (@context) ->
      @context.value = JSON.stringify(@context.value, undefined, 2)
      super @context

