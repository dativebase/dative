define [
  './resources'
  './elicitation-method'
  './../collections/elicitation-methods'
  './../models/elicitation-method'
  './../utils/globals'
], (ResourcesView, ElicitationMethodView, ElicitationMethodsCollection,
  ElicitationMethodModel, globals) ->

  # Elicitation Methods View
  # ------------------------
  #
  # Displays a collection of elicitation methods for browsing, with pagination.
  # Also contains a model-less `ElicitationMethodView` instance for creating new
  # elicitation methods within the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class ElicitationMethodsView extends ResourcesView

    resourceName: 'elicitationMethod'
    resourceView: ElicitationMethodView
    resourcesCollection: ElicitationMethodsCollection
    resourceModel: ElicitationMethodModel

