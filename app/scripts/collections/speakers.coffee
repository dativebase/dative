define [
  './resources'
  './../models/speaker'
], (ResourcesCollection, SpeakerModel) ->

  # Speakers Collection
  # -------------------
  #
  # Holds models for speakers.

  class SpeakersCollection extends ResourcesCollection

    resourceName: 'speaker'
    model: SpeakerModel

