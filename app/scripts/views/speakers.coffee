define [
  './resources'
  './speaker'
  './../collections/speakers'
  './../models/speaker'
  './../utils/globals'
], (ResourcesView, SpeakerView, SpeakersCollection,
  SpeakerModel, globals) ->

  # Speakers View
  # -------------
  #
  # Displays a collection of speakers for browsing, with pagination. Also contains
  # a model-less `SpeakerView` instance for creating new speakers within
  # the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class SpeakersView extends ResourcesView

    resourceName: 'speaker'
    resourceView: SpeakerView
    resourcesCollection: SpeakersCollection
    resourceModel: SpeakerModel

