define [
  'backbone'
  './base'
  './../utils/utils'
  './../utils/globals'
  './../utils/tooltips'
  'jqueryuicolors'
], (Backbone, BaseView, utils, globals, tooltips) ->

  # Form Handler Base View
  # ----------------------
  #
  # This is the common base class of all views that have a FormModel instance as
  # their model. It inherits from `BaseView` and adds methods specific to handling the display of
  # forms.

  class FormHandlerBaseView extends BaseView

    ############################################################################
    # FieldDB stuff
    ############################################################################

    # Return the datumFields of the currently active corpus, if applicable;
    # otherwise null.
    getCorpusDatumFields: ->
      try
        globals.applicationSettings
          .get('activeFieldDBCorpusModel').get 'datumFields'
      catch
        null

    # FieldDB `judgement` values can be any string. Sometimes that string is
    # "grammatical". We want this to be "" when displayed.
    fieldDBJudgementConverter: (grammaticality) ->
      switch grammaticality
        when 'grammatical' then ''
        else grammaticality

    # Return a nice user-facing label for a datum field. I.e., no camelCase nonsense.
    getDatumFieldLabel: (field) ->
      if field?.labelFieldLinguists
        utils.camel2regular field.labelFieldLinguists
      else if field?.label
        utils.camel2regular field.label
      else
        null

    # Get the tooltip for a FieldDB datum field. This is the value of `help` as
    # supplied by FieldDB, if present; otherwise it's the relevant tooltip (if
    # any) defined in the `tooltips` module.
    getFieldDBAttributeTooltip: (attribute, context) =>
      help = @model.getDatumHelp attribute
      if help and attribute isnt 'dateElicited'
        help
      else
        value = @model.getDatumValueSmart attribute
        tooltips("fieldDB.formAttributes.#{attribute}")(
          language: 'eng'
          value: value
        )

    # Getters for arrays that categorize FieldDB datum attributes
    # ---------------------------------------------------------------------------
    #
    # These methods return specific lists of FieldDB Datum "attributes" (i.e.,
    # `datumField` or `sessionField` labels) or true attributes like `.comments`.

    # Get FieldDB form attributes category array.
    # The returned array defines the category of type `category` for FieldDB
    # forms. It is defined in models/application-settings because it should
    # ultimately be user-configurable.
    getFieldDBFormAttributes: (category) =>
      try
        globals.applicationSettings
          .get('fieldDBFormCategories')[category]
      catch
        []

