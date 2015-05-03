define [
  './form-base'
  './../models/form'
], (FormBaseView, FormModel) ->

  # Form Previous Version View
  # --------------------------
  #
  # For displaying a previous version of a form.

  class FormPreviousVersionView extends FormBaseView

    # These actions are not relevant to a previous version resource view.
    excludedActions: [
      'update'
      'delete'
      'history'
    ]

    resourceNameHumanReadable: ->
      'form previous version'

    getHeaderTitle: ->
      "Form #{@model.get('form_id')} on
        #{@utils.humanDatetime @model.get('datetime_modified'), true}"

