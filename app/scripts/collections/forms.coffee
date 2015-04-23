define [
  './resources'
  './../models/form'
], (ResourcesCollection, FormModel) ->

  # Forms Collection
  # ----------------
  #
  # Holds models for forms.

  class FormsCollection extends ResourcesCollection

    resourceName: 'form'
    model: FormModel

