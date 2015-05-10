define [
  './resources'
  './language-model'
  './../collections/language-models'
  './../models/language-model'
], (ResourcesView, LanguageModelView, LanguageModelsCollection,
  LanguageModelModel) ->

  # Language Models View
  # --------------------
  #
  # Displays a collection of language models for browsing, with pagination. Also
  # contains a model-less LanguageModelView instance for creating new
  # language models within the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class LanguageModelsView extends ResourcesView

    resourceName: 'languageModel'
    resourceView: LanguageModelView
    resourcesCollection: LanguageModelsCollection
    resourceModel: LanguageModelModel

