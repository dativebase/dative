define [
  './relational-select-field-with-add-button'
  './../models/syntactic-category'
  './../collections/syntactic-categories'
  './../utils/globals'
], (RelationalSelectFieldWithAddButtonView, SyntacticCategoryModel,
  SyntacticCategoriesCollection, globals) ->

  # Syntactic Category Relational Select(menu) Field, with Add Button, View
  # -----------------------------------------------------------------------
  #
  # For selecting from a list of syntactic categories. With "+" button for
  # creating new ones.

  class SyntacticCategorySelectFieldWithAddButtonView extends RelationalSelectFieldWithAddButtonView

    resourceName: 'syntacticCategory'
    attributeName: 'syntactic_category'
    resourcesCollectionClass: SyntacticCategoriesCollection
    resourceModelClass: SyntacticCategoryModel

