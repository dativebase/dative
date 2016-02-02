define [
  './textarea-input'
  './../templates/collection-contents-input'
], (TextareaInputView, collectionContentsTemplate) ->

  # Collection Contents Input View
  # ------------------------------
  #
  # A view for a data input field that is a textarea for writing the contents
  # of a collection.

  class CollectionContentsInputView extends TextareaInputView

    template: collectionContentsTemplate

    render: ->
      @$el.html @template(@context)
      @tooltipify()
      @bordercolorify()
      @

