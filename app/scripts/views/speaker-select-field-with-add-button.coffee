define [
  './relational-select-field-with-add-button'
  './../models/speaker'
  './../collections/speakers'
  './../utils/globals'
], (RelationalSelectFieldWithAddButtonView, SpeakerModel,
  SpeakersCollection, globals) ->

  # Speaker Relational Select(menu) Field, with Add Button, View
  # ------------------------------------------------------------
  #
  # For selecting from a list of speakers. With "+" button for creating new
  # ones.

  class SpeakerSelectFieldWithAddButtonView extends RelationalSelectFieldWithAddButtonView

    resourceName: 'speaker'
    attributeName: 'speaker'
    resourcesCollectionClass: SpeakersCollection
    resourceModelClass: SpeakerModel

    initialize: (options) ->
      options.selectTextGetter = (option) ->
        "#{option.first_name} #{option.last_name}"
      super

