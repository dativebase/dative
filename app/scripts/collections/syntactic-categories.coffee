define [
  './resources'
  './../models/syntactic-category'
], (ResourcesCollection, SyntacticCategoryModel) ->

  # Syntactic Categories Collection
  # -------------------------------
  #
  # Holds models for syntactic categories.

  class SyntacticCategoriesCollection extends ResourcesCollection

    resourceName: 'syntacticCategory'
    model: SyntacticCategoryModel

