define [
  './resources'
  './../models/elicitation-method'
], (ResourcesCollection, ElicitationMethodModel) ->

  # Elicitation Methods Collection
  # ------------------------------
  #
  # Holds models for elicitation methods.

  class ElicitationMethodsCollection extends ResourcesCollection

    resourceName: 'elicitationMethod'
    model: ElicitationMethodModel


