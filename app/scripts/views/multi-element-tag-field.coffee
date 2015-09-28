define [
  './field'
  './multi-element-tag-input'
], (FieldView, MultiElementTagInputView ) ->

  # Multi-Element Tag View Field View
  # ----------------------------------
  #
  # A view for a data input field that is a jQuery tag-it, cf.
  # https://github.com/aehlke/tag-it.
  #
  # This view allows a user to type the name of an element (likely a tag) and
  # the UI will offer autocomplete suggestions; when a suggestion is chosen (by
  # pressing <Enter>, <Tab> or entering a comma), then the element/tag will be
  # displayed as a widget with an "x" to remove it. If the tag/element does not
  # exist, then a confirm dialog will pop up requesting the user to confirm
  # that they want to create a new such tag/element.

  class MultiElementTagFieldView extends FieldView

    getInputView: ->
      new MultiElementTagInputView  @context

    initialize: (options) ->

      # The attribute that we should use to sort the available tags/elements.
      @sortByAttribute = options.sortByAttribute or 'name'

      # `@context.options` is expected to be an object. `optionsAttribute`
      # should be a key of that object that returns an array to be used as
      # options for building the tag-it widget.
      @optionsAttribute = options.optionsAttribute or options.attribute

      # The name (uncapitalized, camelCase) of the resource that we are
      # associating to via this view.
      @resourceName = options.resourceName or 'tag'

      # The representative attribute of the element we are associating to.
      @representativeAttribute = options.representativeAttribute or 'name'

      super

    getContext: ->
      _.extend(super,
        optionsAttribute: @optionsAttribute
        sortByAttribute: @sortByAttribute
        resourceName: @resourceName
        representativeAttribute: @representativeAttribute
      )

    getValueFromDOM: ->
      @getValueFromArrayOfRelationalIdsFromDOM super

