define [
  './form-base'
  './../models/form'
], (FormBaseView, FormModel) ->

  # Form Previous Version View
  # --------------------------
  #
  # For displaying a previous version of a form.

  class FormPreviousVersionView extends FormBaseView

    initialize: (options) ->
      super options
      @comparatorModel = options.comparatorModel or null
      @truncateAttributes()

    # These actions are not relevant to a previous version form view.
    excludedActions: [
      'update'
      'delete'
      'history'
      'data'
    ]

    resourceNameHumanReadable: ->
      'form previous version'

    getHeaderTitle: ->
      "Form #{@model.get('form_id')} on
        #{@utils.humanDatetime @model.get('datetime_modified'), true}"

    render: ->
      super
      @diffThis()
      @

    # We don't display some form attributes for a form's previous version
    # either because they're confusing (e.g., `id` is the previous verson's id,
    # not the form's) or because they're constant (e.g., `UUID`, `enterer`).
    truncateAttributes: ->
      @secondaryAttributes = _.without(@secondaryAttributes, 'id', 'UUID',
        'enterer', 'datetime_entered', 'datetime_modified')

