define [
  './resources'
  './../models/language'
], (ResourcesCollection, LanguageModel) ->

  # Languages Collection
  # --------------------
  #
  # Holds models for languages.

  class LanguagesCollection extends ResourcesCollection

    resourceName: 'language'
    model: LanguageModel




