define [
  './relational-select-field-with-add-button'
  './../models/elicitation-method'
  './../collections/elicitation-methods'
], (RelationalSelectFieldWithAddButtonView, ElicitationMethodModel,
  ElicitationMethodsCollection) ->

  # Relational Select(menu) Field, with Add Button, View
  # ----------------------------------------------------
  #
  # A specialized SelectFieldView for OLD relational fields where there is also
  # a "+" button at the righthand side that results in a view for creating a
  # new resource being displayed in a dialog box.
  #
  # TODO: listen for create success and update the select options in response
  # ...

  class ElicitationMethodSelectFieldWithAddButtonView extends RelationalSelectFieldWithAddButtonView

    resourceName: 'elicitationMethod'
    attributeName: 'elicitation_method'
    resourcesCollectionClass: ElicitationMethodsCollection
    resourceModelClass: ElicitationMethodModel

