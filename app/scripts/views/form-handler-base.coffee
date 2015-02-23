define [
  './base'
  './../utils/globals'
  './../utils/tooltips'
  'jqueryuicolors'
], (BaseView, globals, tooltips) ->

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
        @utils.camel2regular field.labelFieldLinguists
      else if field?.label
        @utils.camel2regular field.label
      else
        null

    # Get the tooltip for a FieldDB datum field. This is the value of `help` as
    # supplied by FieldDB, if present; otherwise it's the relevant tooltip (if
    # any) defined in the `tooltips` module.
    getFieldDBAttributeTooltip: (attribute) =>
      # console.log "in getFieldDBAttributeTooltip with #{attribute}"
      help = @model.getDatumHelp attribute
      if help and attribute isnt 'dateElicited'
        # console.log "returning help: #{help}"
        help
      else
        value = @model.getDatumValueSmart attribute
        tooltip = tooltips("fieldDB.formAttributes.#{attribute}")(
          language: 'eng'
          value: value
        )
        # console.log "returning tooltip: #{tooltip}"
        tooltip

    # Get an array of form attributes (form app settings model) for the
    # specified server type and category (e.g., 'igt' or 'secondary').
    getFormAttributes: (serverType, category) ->
      switch serverType
        when 'FieldDB' then attribute = 'fieldDBFormCategories'
        when 'OLD' then attribute = 'oldFormCategories'
      try
        globals.applicationSettings.get(attribute)[category]
      catch
        console.log "WARNING: could not get an attributes array for
          #{serverType} and #{category}"
        []

    ############################################################################
    # OLD stuff
    ############################################################################

    # Return the tooltip for an OLD form attribute (uses the imported `tooltip`
    # module). Note that we pass `value` in case `tooltip` uses it in generating
    # a value-specific tooltip (which isn't always the case.)
    getOLDAttributeTooltip: (attribute) ->
      tooltipGenerator = tooltips("old.formAttributes.#{attribute}")
      value = @model.get attribute
      tooltipGenerator(
        language: 'eng' # TODO: make 'eng' configurable
        value: value
      )

