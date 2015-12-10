define ['./resource'], (ResourceModel) ->

  # OLD Application Settings Model
  # ------------------------------
  #
  # A Backbone model for an OLD server's application-wide settings.

  class OLDApplicationSettingsModel extends ResourceModel

    resourceName: 'oldApplicationSettings'
    serverSideResourceName: 'applicationsettings'

    manyToOneAttributes: [
      'storage_orthography'
      'input_orthography'
      'output_orthography'
    ]

    manyToManyAttributes: [
      'unrestricted_users'
    ]

    ############################################################################
    # OLDApplicationSettings Schema
    ############################################################################

    defaults: ->

      id: null
      object_language_name: '' # 255 chrs max
      object_language_id: '' # 3 chrs max, ISO 639-3 3-char Id code
      metalanguage_name: '' # 255 chrs max
      metalanguage_id: '' # 3 chrs max, ISO 639-3 3-char Id code
      metalanguage_inventory: '' # long text; Don't think this is really used for any OLD-side logic.
      orthographic_validation: 'None' # one of 'None', 'Warning', or 'Error'
      narrow_phonetic_inventory: '' # long text; should be comma-delimited graphemes
      narrow_phonetic_validation: '' # one of 'None', 'Warning', or 'Error'
      broad_phonetic_inventory: '' # long text; should be comma-delimited graphemes
      broad_phonetic_validation: '' # one of 'None', 'Warning', or 'Error'
      morpheme_break_is_orthographic: false # boolean
      morpheme_break_validation: ''  # one of 'None', 'Warning', or 'Error'
      phonemic_inventory: '' # long text; should be comma-delimited graphemes
      morpheme_delimiters: '' # 255 chars max; should be COMMA-DELIMITED single chars...
      punctuation: '' # long text; should be punctuation chars
      grammaticalities: '' # 255 chars max ...
      storage_orthography: null # id of an orthography
      input_orthography: null # id of an orthography
      output_orthography: null # id of an orthography
      datetime_modified: ''
      unrestricted_users: [] # an array of users who are "unrestricted". In the OLD this is a m2m relation, I think.
      # orthographies: [] # OLD's schema suggests this is an attr, but it's app sett model doesn't ...

    editableAttributes: [
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
      'unrestricted_users'
    ]

    getValidator: (attribute) ->
      switch attribute
        when 'metalanguage_id' then @realISOLanguageId
        when 'object_language_id' then @realISOLanguageId
        else null

    realISOLanguageId: (value) ->
      if value.trim()
        if value in @languageRefNames
          null
        else
          "#{value} is not a valid ISO 639-3 language Id; please enter a valid
            Id or nothing at all."
      else
        null

