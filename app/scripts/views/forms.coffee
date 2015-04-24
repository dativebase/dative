define [
  './resources'
  './form'
  './../collections/forms'
  './../models/form'
], (ResourcesView, FormView, FormsCollection, FormModel) ->

  # Forms View
  # ----------
  #
  # Displays a collection of forms for browsing, with pagination. Also
  # contains a model-less FormView instance for creating new forms
  # within the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class SubcorporaView extends ResourcesView

    resourceName: 'form'
    resourceView: FormView
    resourcesCollection: FormsCollection
    resourceModel: FormModel

    initialize: (options) ->
      options.enumerateResources = true
      super options

