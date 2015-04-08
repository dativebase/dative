define [
  './resources'
  './phonology'
  './../collections/phonologies'
  './../models/phonology'
], (ResourcesView, PhonologyView, PhonologiesCollection, PhonologyModel) ->

  # Phonologies View
  # ----------------
  #
  # Displays a collection of phonologies for browsing, with pagination. Also
  # contains a model-less PhonologyView instance for creating new phonologies
  # within the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class PhonologiesView extends ResourcesView

    resourceName: 'phonology'
    resourceView: PhonologyView
    resourcesCollection: PhonologiesCollection
    resourceModel: PhonologyModel

