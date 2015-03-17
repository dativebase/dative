define [
  './field-display'
  './value-representation'
], (FieldDisplayView, ValueRepresentationView) ->

  # Person Field Display View
  # -------------------------
  #
  # A view for displaying a person field. Note: currently tailored only for
  # OLD-style "persons", i.e., objects with `first_name` and `last_name`
  # attributes.

  class PersonFieldDisplayView extends FieldDisplayView

    getContext: ->
      context = super
      try
        firstName = context.value.first_name or ''
        lastName = context.value.last_name or ''
        context.value = "#{firstName} #{lastName}".trim()
      catch
        context.value = ''
      context

