define [
  './resource-select-via-search-input'
  './related-resource-representation'
  './array-of-related-resources-representation-set'
  './selected-resource-wrapper'
], (ResourceSelectViaSearchInputView, RelatedResourceRepresentationView,
  ArrayOfRelatedResourcesRepresentationSetView, SelectedResourceWrapperView) ->

  class MyRelatedResourceRepresentationView extends RelatedResourceRepresentationView

    getRelatedResourceId: ->
      try
        _.findWhere(@context.model.get("#{@attributeName}"),
          {id: @context.selectedResourceId}).id
      catch
        console.log 'Error: could not get an id for a related resource
          representation view in the resources-select-via-search input'
        null


  # Resources Select Via Search Input View
  # --------------------------------------
  #
  # A view for selecting *zero or more of* a particular resource (say, for a
  # many-to-many  relation) by searching for it in a search input. This input
  # performs a "smart" search; i.e., it tries to understand what the user may
  # be searching for without exposing a complex interface.
  #
  # Note: this view will only work when searching over resources that expose a
  # server-side search interface. For the OLD, the only such resources are
  # currently:
  #
  # - forms (and their backups)
  # - files
  # - collections (and their backups)
  # - form searches
  # - sources
  # - languages

  class ResourcesSelectViaSearchInputView extends ResourceSelectViaSearchInputView

    # This is the class that is used to display the *selected* resources. Note
    # that this is an override of the superclass's
    # `RelatedResourceRepresentationView`---here we need an array of related
    # resource representations to display what has been selected.
    selectedResourceViewClass: MyRelatedResourceRepresentationView

    selectedResourceWrapperViewClass: SelectedResourceWrapperView

    getMultiSelect: -> true

    initialize: (context) ->

      # This will hold the *array of* resource models that the user selects (/
      # has selected).
      @selectedResourceModels = []

      # This will hold the *array of* resource views for the selected models.
      @selectedResourceViews = []

      @selectedResourceViewsRendered = false
      @selfSet = false

      super context

    refresh: (@context) ->
      # `@selfSet` will be `true` when we have set our own value.
      if @selfSet
        @selfSet = false
      else
        @setStateBasedOnSelectedValue()
        @selectedResourceViewsRendered = false
        @render()
        # If we have an existing search term, then we perform the search again
        # to refresh the search results display.
        if @searchTerm isnt null then @performSearch @searchTerm

    # If we have one or more selected values, cause them to be displayed.
    # NOTE: we keep the search interface visible even when resources are
    # selected because the user may want to search for more.
    setStateBasedOnSelectedValue: ->
      @selectedResourceModels = []
      if @context.value.length > 0
        for resourceObject in @context.value
          @selectedResourceModels.push(new @resourceModelClass(resourceObject))
        @searchInterfaceVisible = true
        @selectedResourceViewsVisible = true
      else
        @searchInterfaceVisible = true
        @selectedResourceViewsVisible = false

    # Return `true` if we have something selected.
    weHaveSelected: -> @selectedResourceModels.length > 0

    # Render/display any selected resource(s).
    selectedVisibility: ->
      if @weHaveSelected()
        if @selectedResourceViewsRendered
          @showSelectedResourceViews()
        else
          @renderSelectedResourceViews()
      else
        @selectedResourceViewsVisibility()

    closeCurrentSelectedResourceViews: ->
      for selectedResourceView in @selectedResourceViews
        selectedResourceView.close()
        @closed selectedResourceView

    # Return an instance of `@selectedResourceViewClass` for the selected
    # resource. Note that this method assumes that this view class is a
    # sub-class of `RelatedResourceRepresentationView`, hence the particular
    # params passed on initialization. Override this method on sub-classes.
    getSelectedResourceViews: ->
      selectedResourceViews = []
      for selectedResourceModel in @selectedResourceModels
        params =
          selectedResourceId: selectedResourceModel.get('id')
          value: selectedResourceModel.attributes
          class: 'field-display-link dative-tooltip'
          resourceAsString: @resourceAsString
          valueFormatter: (v) -> v
          resourceName: @resourceName
          attributeName: @context.attribute
          resourceModelClass: @resourceModelClass
          resourcesCollectionClass: @resourcesCollectionClass
          resourceViewClass: null
          model: @getModelForSelectedResourceView()
        if @selectedResourceWrapperViewClass
          selectedResourceView = new @selectedResourceWrapperViewClass(
            @selectedResourceViewClass, params)
        else
          selectedResourceView = new @selectedResourceViewClass params
        selectedResourceViews.push selectedResourceView
      selectedResourceViews

    # Render the view for the resource that the user has selected.
    renderSelectedResourceViews: ->
      @closeCurrentSelectedResourceViews()
      @selectedResourceViews = @getSelectedResourceViews()
      $container = @$('.selected-resource-display-container').first()

      fragment = document.createDocumentFragment()
      for view in @selectedResourceViews
        fragment.appendChild view.render().el
        @rendered view
      $container.html fragment

      @listenToSelectedResourceViews()
      @selectedResourceViewsVisible = true
      @selectedResourceViewsRendered = true
      @containerAppearance $container
      @selectedResourceViewsVisibility()
      @$('button.deselect').first().focus().select()
      @renderSelectedResourceViewsPost()

    # Do something special after the views for the selected resources have been
    # rendered.
    renderSelectedResourceViewsPost: ->

    listenToSelectedResourceViews: ->
      for view in @selectedResourceViews
        @listenTo view, 'deselect', @deselectResourceView

    setSelectedToModel: ->
      value = (m.attributes for m in @selectedResourceModels)
      @selfSet = true
      @model.set @context.attribute, value

    # Return the model of the selected resource view, given that view as input.
    # The tricky bit is that view could have a wrapper view around it.
    getSelectedModelFromSelectedResourceView: (view) ->
      if view instanceof SelectedResourceWrapperView
        view = view.selectedResourceView
      id = _.findWhere(view.model.get(view.attributeName),
        {id: view.context.selectedResourceId}).id
      models = (m for m in @selectedResourceModels when m.get('id') is id)
      if models.length is 1
        models[0]
      else
        console.log 'unable to find a model for this view ...'
        console.log view
        null

    deselectResourceView: (resourceView) ->
      modelToBeDeselected = @getSelectedModelFromSelectedResourceView resourceView
      newSelectedResourceViews = []
      for view in @selectedResourceViews
        if view is resourceView
          view.close()
          @closed view
        else
          newSelectedResourceViews.push view
      @selectedResourceViews = newSelectedResourceViews
      @selectedResourceModels =
        (m for m in @selectedResourceModels when m isnt modelToBeDeselected)
      @setSelectedToModel()
      @trigger 'validateMe'

    # Set the relevant attribute of our model to the model of the
    # passed-in `resourceAsRowView`
    selectResourceAsRowView: (resourceAsRowView) ->
      selectedResourceIds = (m.get('id') for m in @selectedResourceModels)
      if resourceAsRowView.model.get('id') in selectedResourceIds
        Backbone.trigger 'resourceAlreadySelected', @resourceName,
          resourceAsRowView.model.get('id')
      else
        @selectedResourceModels.push resourceAsRowView.model
        @setSelectedToModel()
        @renderSelectedResourceViews()
        @trigger 'validateMe'

    onClose: -> @selectedResourceViewsRendered = false


    # Selected Resource Views
    ############################################################################

    # Make the selected resource view visible, or not, depending on state.
    selectedResourceViewsVisibility: ->
      if @selectedResourceViewsVisible
        @showSelectedResourceViews()
      else
        @hideSelectedResourceViews()

    showSelectedResourceViews: ->
      @selectedResourceViewsVisible = true
      @$('.selected-resource-display-container').first().show()

    hideSelectedResourceViews: ->
      @selectedResourceViewsVisible = false
      @$('.selected-resource-display-container').first().hide()

    toggleSelectedResourceViews: ->
      if @selectedResourceViewsVisible
        @hideSelectedResourceViews()
      else
        @showSelectedResourceViews()

    showSelectedResourceViewsAnimateCheck: ->
      if @$('.selected-resource-display-container').is ':hidden'
        @showSelectedResourceViewsAnimate()

    showSelectedResourceViewsAnimate: ->
      @selectedResourceViewsVisible = true
      @$('.selected-resource-display-container').first().slideDown()

    hideSelectedResourceViewsAnimate: (complete=->) ->
      @selectedResourceViewsVisible = false
      @$('.selected-resource-display-container').first().slideUp
        complete: complete

    hideSelectedResourceViewsAnimateCheck: (complete=->) ->
      if @$('.selected-resource-display-container').is ':visible'
        @hideSelectedResourceViewsAnimate complete

    toggleSelectedResourceViewsAnimate: ->
      if @selectedResourceViewsVisible
        @hideSelectedResourceViewsAnimate()
      else
        @showSelectedResourceViewsAnimate()

    # Respond to the event signaling that our new resource was created. We
    # select this new resource in the resource select UI.
    newResourceCreated: (resourceModel) ->

      # We save the newly minted model for later, but anticipate not using it.
      @lastNewResourceModel = @newResourceModel
      @stopListening @newResourceModel
      @newResourceModel = null

      x = =>
        attributeName = @context.attribute
        @model.get(attributeName).push resourceModel.attributes
        @refresh @context
      setTimeout x, 500

