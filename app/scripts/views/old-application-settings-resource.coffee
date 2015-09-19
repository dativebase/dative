define [
  './resource'
  './old-application-settings-add-widget'
  './date-field-display'
], (ResourceView, OLDApplicationSettingsAddWidgetView, DateFieldDisplayView) ->

  # OLD Application Settings View
  # -----------------------------
  #
  # For displaying individual OLD application settings models/resources.

  class OLDApplicationSettingsResourceView extends ResourceView

    resourceName: 'oldApplicationSettings'

    resourceAddWidgetView: OLDApplicationSettingsAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: [
      'object_language_name'
      'object_language_id'
      'metalanguage_name'
      'metalanguage_id'
      'metalanguage_inventory'
      'orthographic_validation'
      'narrow_phonetic_inventory'
      'narrow_phonetic_validation'
      'broad_phonetic_inventory'
      'broad_phonetic_validation'
      'morpheme_break_is_orthographic'
      'morpheme_break_validation'
      'phonemic_inventory'
      'morpheme_delimiters'
      'punctuation'
      'grammaticalities'
      'storage_orthography'
      'input_orthography'
      'output_orthography'
      'datetime_modified'
      'unrestricted_users'
      'id'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: []

    # Map attribute names to display view class names.
    attribute2displayView:
      datetime_modified: DateFieldDisplayView


