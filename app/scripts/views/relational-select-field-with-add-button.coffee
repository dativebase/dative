define [
  './relational-select-field'
  './select-input-with-add-button'
  './../models/resource'
  './../collections/resources'
  './../utils/globals'
], (RelationalSelectFieldView, SelectInputWithAddButtonView, ResourceModel,
  ResourcesCollection, globals) ->

  # Relational Select(menu) Field, with Add Button, View
  # ----------------------------------------------------
  #
  # A specialized SelectFieldView for OLD relational fields where there is also
  # a "+" button at the righthand side that results in a view for creating a
  # new resource being displayed in a dialog box.
  #
  # TODO: listen for create success and update the select options in response
  # ...

  class RelationalSelectFieldWithAddButtonView extends RelationalSelectFieldView

    resourceName: 'resource' # e.g., 'elicitationMethod'
    attributeName: 'resource' # e.g., 'elicitation_method'
    resourcesCollectionClass: ResourcesCollection # e.g., ElicitationMethodsCollection
    resourceModelClass: ResourceModel # e.g., ElicitationMethodModel

    initialize: (options) ->
      options.width = '90%'
      super options
      @newResourceModel = null

    getInputView: ->
      new SelectInputWithAddButtonView @context

    # Override this in a subclass to provide non-standard contextual attributes.
    # Input views expect a context object to be passed to their constructors,
    # which they will in turn pass to their templates.
    getContext: ->
      context = super
      context.buttonClass = 'create-new-resource'
      context.buttonIconClass = 'fa-plus'
      context.buttonTooltip = "Click here to create a new
        #{@utils.camel2regular(@utils.capitalize(@resourceName))} in the page"
      context

    events:
      'click .create-new-resource': 'createNewResource'

    # Cause an "Add New Resource" view to be displayed in a dialog box.
    createNewResource: ->
      console.log 'create new resource'
      if @newResourceModel
        @requestDialogView()
      else
        @resourcesCollection = new @resourcesCollectionClass()
        @newResourceModel =
          new @resourceModelClass({}, {collection: @resourcesCollection})
        @requestDialogView()

    # Sometimes circular dependencies arise if we try to import a particular
    # ResourceView sub-class. If `@resourceViewClass` is undefined, then we let
    # the event listener supply the appropriate view class for the model.
    requestDialogView: ->
      Backbone.trigger 'showResourceModelInDialog', @newResourceModel,
        @resourceName

      # We save the newly minted model for later, but anticipate not using it.
      @lastNewResourceModel = @newResourceModel
      @newResourceModel = null

      console.log globals

