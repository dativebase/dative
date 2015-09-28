define [
  './resources'
  './syntactic-category'
  './../collections/syntactic-categories'
  './../models/syntactic-category'
  './../utils/globals'
], (ResourcesView, SyntacticCategoryView, SyntacticCategoriesCollection,
  SyntacticCategoryModel, globals) ->

  # Syntactic Categories View
  # -------------------------
  #
  # Displays a collection of syntactic categories for browsing, with pagination.
  # Also contains a model-less `SyntacticCategoryView` instance for creating new
  # syntactic categories within the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class SyntacticCategoriesView extends ResourcesView

    resourceName: 'syntacticCategory'
    resourceView: SyntacticCategoryView
    resourcesCollection: SyntacticCategoriesCollection
    resourceModel: SyntacticCategoryModel


