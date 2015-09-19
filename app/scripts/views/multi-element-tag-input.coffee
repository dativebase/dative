define [
  './input'
  './tag'
  './../models/tag'
  './../collections/tags'
  './../templates/multi-element-tag-input'
], (InputView, TagView, TagModel, TagsCollection, multiElementTagInputTemplate) ->

  # Mulit-Element Tag Input View
  # ----------------------------
  #
  # A view for a data input field that allows a user to select zero or more
  # elements in a text input field that auto-completes and makes the selected
  # elements look like tags with little "x"es to close them. This is based on
  # the jquery/tag-it library: https://github.com/aehlke/tag-it, but with some
  # modifications, for which see jquery-extensions/tag-it.js.

  class MultiElementTagInputView extends InputView

    # These attributes should be replaced with the appropriate view, model, and
    # collection. This view assumes that it is for associating tags, but it
    # could be used for other resources/elements as well.
    resourceView: TagView
    resourceModel: TagModel
    resourceCollection: TagsCollection

    events:
      'focus .ui-autocomplete-input': 'focus'
      'blur .ui-autocomplete-input': 'blur'

    # We have to use JS to add and remove the box-shadow on focus/blur.
    focus: -> @$('ul').first().css 'boxShadow', '0 0 10px orange'

    blur: -> @$('ul').first().css 'boxShadow', 'none'

    template: multiElementTagInputTemplate

    render: ->
      super
      @tagitify()
      @tooltipify()
      @$('ul.tagit').css "border-color", @constructor.jQueryUIColors().defBo
      @

    listenToEvents: ->
      super
      @listenTo @, 'createResource', @createResource
      @listenTo @, 'cancelCreateResource', @cancelCreateResource

    # The user has clicked "Ok" in the confirm dialog and wants to create a
    # non-existent tag/element. We do the work here of trying to create it.
    # NOTE: we are assuming that `@context.representativeAttribute` is the only
    # attribute that needs valuation. For some objects/resources this will not
    # be the case. That is, creating a new source on the fly may require more
    # than just providing the source's citation form. We may therefore need to
    # later change this so that a bona fide "Add New Resource" widget is
    # rendered so that the user can fill in the appropriate values.
    createResource: (representativeAttributeValue) ->
      try
        elementCollection = new @resourceCollection()
        elementModel = new @resourceModel({}, collection: elementCollection)
        elementModel.set @context.representativeAttribute,
          representativeAttributeValue
        r = @utils.capitalize @context.resourceName
        @listenToOnce elementModel, "add#{r}Fail", @createResourceFail
        @listenToOnce elementModel, "add#{r}Success", @createResourceSuccess
        elementModel.collection.addResource elementModel
      catch
        @removeElement representativeAttributeValue

    # The user has hit the cancel button on the confirm dialog here.
    cancelCreateResource: (representativeAttributeValue) ->
      @removeElement representativeAttributeValue

    # If we fail to create the new tag/element, we remove it from the tag-it UI.
    createResourceFail: (error, resource) ->
      @removeElement resource.get(@context.representativeAttribute)

    # If we succeed in creating the new tag/element, we must add it to our
    # arrays of available options; we also need to tell our parent field view
    # to set our selected elements to the model.
    createResourceSuccess: (resource) ->
      options = @context.options[@context.optionsAttribute]
      resourceObject = id: resource.get('id')
      resourceObject[@context.representativeAttribute] =
        resource.get @context.representativeAttribute
      options.push resourceObject
      @setAvailableElements options
      @$(".#{@context.class}").first()
        .tagit 'updateTags', @availableElementsAsStrings, false
      @trigger 'setToModel'

    # Remove the element with label `elementLabel` from the tag-it UI.
    removeElement: (elementLabel) ->
      try
        @$(".#{@context.class}").first()
          .tagit 'removeTagByLabel', elementLabel

    setAvailableElements: (options) ->
      @availableElements =
        _.sortBy(options, (x) => x[@context.sortByAttribute].toLowerCase())
      @availableElementsAsStrings =
        (o[@context.representativeAttribute] for o in @availableElements)

    # Make the <ul> into a tag-it interface.
    tagitify: ->
      options = @context.options[@context.optionsAttribute]
      @setAvailableElements options
      @$(".#{@context.class}").first().tagit
        availableTags: @availableElementsAsStrings
        allowSpaces: true
        beforeTagAdded: (event, ui) => @checkIfElementExists event, ui
        afterTagAdded: (event, ui) => @afterTagAdded event, ui
        afterTagRemoved: (event, ui) => @afterTagRemoved event, ui

    afterTagAdded: (event, ui) -> @trigger 'setToModel'

    afterTagRemoved: (event, ui) -> @trigger 'setToModel'

    checkIfElementExists: (event, ui) ->
      if ui.tagLabel not in @availableElementsAsStrings
        # Trigger opening of a confirm dialog: if user clicks "Ok", then a new
        # element will be added.
        options =
          text: "There is no #{@context.resourceName} with the
            #{@context.representativeAttribute} “#{ui.tagLabel}”. Would you like
            to create it now?"
          confirm: true
          confirmEvent: "createResource"
          confirmArgument: ui.tagLabel
          cancelEvent: "cancelCreateResource"
          cancelArgument: ui.tagLabel
          eventTarget: @
          focusButton: 'ok'
        Backbone.trigger 'openAlertDialog', options

    # Make title attrs into jQueryUI tooltips.
    tooltipify: ->
      @$(".#{@context.class}").first()
        .tooltip
          position: @tooltipPositionLeft '-200'

    # Given the label of a tag-it element/tag, return its id value.
    idFromLabel: (label) ->
      finder = {}
      finder[@context.representativeAttribute] = label
      object = _.findWhere @availableElements, finder
      try
        object.id
      catch
        null

    # Overrides the `InputView` base class's `getValueFromDOM`. Returns an
    # object with one attribute whose value is an array of numeric ids.
    getValueFromDOM: ->
      assignedTags = @$(".#{@context.class}").first().tagit 'assignedTags'
      idsArray = (@idFromLabel(e) for e in assignedTags)
      idsArray = (e for e in idsArray when e)
      result = {}
      result[@context.attribute] = idsArray
      result

    # These do nothing, but they may be needed elsewhere ...
    disable: ->
    enable: ->

