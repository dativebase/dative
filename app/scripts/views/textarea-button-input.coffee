define [
  'backbone'
  './input'
  './../templates/textarea-button-input'
], (Backbone, InputView, textareaButtonTemplate) ->

  # Textarea Button Input View
  # ---------------------------------
  #
  # A view for a set of input controls consisting of:
  # - a <textarea>
  # - a <button> for deleting the textarea/button set.

  class TextareaButtonInputView extends InputView

    className: 'dative-field-subinput-container'

    template: textareaButtonTemplate

    initialize: (@context) ->
      # The element of this view will have a class like "translations-0" where
      # "0" is a unique index in the array of translations.
      @selectClass = @context.selectClass
      @$el.addClass "#{@context.attribute}-#{@context.index}"

    events:
      'click button.new': 'newTextareaButtonInputView'
      'click button.remove': 'removeMe'

    # The adding of a new select-textarea-button input view is handled by this
    # view's superview: `TranslationsInputView`.
    newTextareaButtonInputView: -> @trigger 'new'

    # The removing of a new select-textarea-button input view is also handled
    # by this view's superview: `TranslationsInputView`.
    removeMe: ->
      @trigger 'remove', @context.index

    render: ->
      @$el.html @template(@context)
      @tooltipify()
      @buttonify()
      @autosize()
      @bordercolorify()
      @listenToEvents()
      @

    # Make title attrs into jQueryUI tooltips.
    tooltipify: ->
      @$('textarea.dative-tooltip')
        .tooltip
          position: @tooltipPositionLeft '-250'
      @$('button')
        .tooltip
          position: @tooltipPositionRight()

