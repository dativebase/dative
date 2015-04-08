define [
  './resources'
  './../models/phonology'
], (ResourcesCollection, PhonologyModel) ->

  # Phonollogies Collection
  # -----------------------
  #
  # Holds models for phonologies.

  class PhonologiesCollection extends ResourcesCollection

    resourceName: 'phonology'
    model: PhonologyModel

