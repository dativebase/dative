define [
  './resources'
  './../models/language-model'
], (ResourcesCollection, LanguageModelModel) ->

  # Language Models Collection
  # --------------------------
  #
  # Holds models for language models.

  class LanguageModelsCollection extends ResourcesCollection

    resourceName: 'languageModel'
    model: LanguageModelModel

    serverSideResourceName: 'morphemelanguagemodels'

