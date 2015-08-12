define [
  './resource'
  './field-display'
  './related-resource-representation'
  './../models/resource'
  './../collections/resources'
], (ResourceView, FieldDisplayView, RelatedResourceRepresentationView,
  ResourceModel, ResourcesCollection) ->

  # Related Resource Field Display View
  # -----------------------------------
  #
  # This is a field display that displays a related resource (e.g., a form's
  # enterer) as a descriptive link that, when clicked retrieves the resource
  # data from the server and causes it to be displayed in a dialog box.

  class RelatedResourceFieldDisplayView extends FieldDisplayView

    # Override these in sub-classes.
    resourceName: 'resource'
    attributeName: 'resource'
    resourceModelClass: ResourceModel
    resourcesCollectionClass: ResourcesCollection
    resourceViewClass: ResourceView
    relatedResourceRepresentationViewClass: RelatedResourceRepresentationView

    # This method should return a string representation of the related resource.
    resourceAsString: (resource) -> resource.name

    # Override this in a subclass to swap in a new representation view.
    getRepresentationView: ->
      new @relatedResourceRepresentationViewClass @context

    getContext: ->
      context = super
      context.resourceAsString = @resourceAsString
      context.resourceName = @resourceName
      context.attributeName = @attributeName
      context.resourceModelClass = @resourceModelClass
      context.resourcesCollectionClass = @resourcesCollectionClass
      context.resourceViewClass = @resourceViewClass
      context.relatedResourceRepresentationViewClass =
        @relatedResourceRepresentationViewClass
      context

    # Return an in-line CSS style to hide the HTML of an empty form attribute
    # Note the use of `=>` so that the ECO template knows to use this view's
    # context.
    shouldBeHidden: ->
      value = @context.value
      if _.isDate(value) or _.isNumber(value) or _.isBoolean(value)
        false
      else if _.isEmpty(value) or @isValueless(value)
        true
      else
        false

