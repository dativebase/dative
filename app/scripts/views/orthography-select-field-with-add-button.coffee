define [
  './relational-select-field-with-add-button'
  './../models/orthography'
  './../collections/orthographies'
  './../utils/globals'
], (RelationalSelectFieldWithAddButtonView, OrthographyModel,
  OrthographiesCollection, globals) ->

  # Orthography Relational Select(menu) Field, with Add Button, View
  # ----------------------------------------------------------------
  #
  # For selecting from a list of orthographeis. With "+" button for creating new
  # ones.

  class OrthographySelectFieldWithAddButtonView extends RelationalSelectFieldWithAddButtonView

    resourceName: 'orthography'
    attributeName: 'storage_orthography'
    resourcesCollectionClass: OrthographiesCollection
    resourceModelClass: OrthographyModel

    initialize: (options) ->
      options.optionsAttribute = 'orthographies'
      options.selectTextGetter = (option) ->
        option.name
      super


