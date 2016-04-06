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

    ############################################################################
    # Logic for Input Validation
    ############################################################################

    # These methods allow the OLD application settings' orthography, inventory
    # and validation-related attributes to effect validation of transcription,
    # phonetic transcription, and morpheme break values.

    # Return a validator (a `RegExp` instance) that returns `true` if the input
    # of the specified field is valid.
    getInputValidator: (targetField) ->
      switch targetField
        when 'orthographic transcription'
          @getOrthographicValidator()
        when 'transcription'
          @getOrthographicValidator()
        when 'narrow phonetic transcription'
          @getNarrowPhoneticValidator()
        when 'narrow_phonetic_transcription'
          @getNarrowPhoneticValidator()
        when 'broad phonetic transcription'
          @getBroadPhoneticValidator()
        when 'phonetic_transcription'
          @getBroadPhoneticValidator()
        when 'phonetic transcription'
          @getBroadPhoneticValidator()
        else
          @getMorphemeBreakValidator()

    # Return a RegExp that validates orthographic transcription values. This
    # allows:
    # - graphs from the storage orthography,
    # - capitalized graphs from the storage orthography,
    # - punctuation characters, and
    # - the space character
    getOrthographicValidator: ->
      inventory = @getInventoryFromStorageOrthography()
      if inventory
        graphs = inventory.split ','
        escapedGraphs = (@utils.escapeRegexChars(g) for g in graphs)
        punctuation =
          (@utils.escapeRegexChars(p) for p in @get('punctuation').split(''))
        capitalizedGraphs =
          (@utils.escapeRegexChars(@utils.capitalize(g)) for g in graphs)
        elements = escapedGraphs.concat punctuation, capitalizedGraphs
        new RegExp "^(#{elements.join '|'}| )*$"
      else
        null

    # Get an inventory string (i.e., an orthography) from the storage
    # orthography object in application settings.
    getInventoryFromStorageOrthography: ->
      orthography = @get 'storage_orthography'
      if orthography
        orthography.orthography
      else
        null

    # Return a RegExp that validates narrow phonetic transcription values. This
    # allows:
    # - graphs from the narrow phonetic inventory and
    # - the space character
    getNarrowPhoneticValidator: ->
      inventory = @get 'narrow_phonetic_inventory'
      if inventory
        graphs = inventory.split ','
        escapedGraphs = (@utils.escapeRegexChars(g) for g in graphs)
        new RegExp "^(#{escapedGraphs.join '|'}| )*$"
      else
        null

    # Return a RegExp that validates phonetic transcription values. This
    # allows:
    # - graphs from the broad phonetic inventory and
    # - the space character
    getBroadPhoneticValidator: ->
      inventory = @get 'broad_phonetic_inventory'
      if inventory
        graphs = inventory.split ','
        escapedGraphs = (@utils.escapeRegexChars(g) for g in graphs)
        new RegExp "^(#{escapedGraphs.join '|'}| )*$"
      else
        null

    # Return a RegExp that validates morpheme break values. This allows:
    # - graphs from the storage orthography XOR phonemic inventory,
    # - capitalized graphs from the storage orthography XOR phonemic inventory,
    # - morpheme delimiters, and
    # - the space character
    getMorphemeBreakValidator: ->
      if @get 'morpheme_break_is_orthographic'
        inventory = @getInventoryFromStorageOrthography()
      else
        inventory = @get 'phonemic_inventory'
      if inventory
        graphs = inventory.split ','
        escapedGraphs = (@utils.escapeRegexChars(g) for g in graphs)
        delimiters =
          (@utils.escapeRegexChars(d) for d in @get('morpheme_delimiters').split(','))
        # A phonemic inventory should not have its graphs automatically
        # capitalized since capitalization may have phonological meaning.
        if @get 'morpheme_break_is_orthographic'
          capitalizedGraphs =
            (@utils.escapeRegexChars(@utils.capitalize(g)) for g in graphs)
          elements = escapedGraphs.concat delimiters, capitalizedGraphs
        else
          elements = escapedGraphs.concat delimiters
        new RegExp "^(#{elements.join '|'}| )*$"
      else
        null

