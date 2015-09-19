define ['./resource'], (ResourceModel) ->

  # OLD Application Settings Model
  # ------------------------------
  #
  # A Backbone model for an OLD server's application-wide settings.

  class OLDApplicationSettingsModel extends ResourceModel

    resourceName: 'oldApplicationSettings'

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
      punctuation: '' # long text; should be comma-delimited punctuation chars
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
        when 'name' then @requiredString
        else null

    ###
    Here is what the OLD v. 0.2 interface says about orthographies. Note that
    the current version of the OLD does not, server-side, use orthographies for
    anything. That is, it is expected (I think) that the client will handle
    conversion between orthographies.

    An [object language] orthography is an ordered list of graphemes (or
    polygraphs) that can be used to write [orthographic object] language data.
    Graphemes must be separated by commas.

    The order of graphemes is important for collation purposes. Graphemes that
    are not ordered relative to one another (e.g, a vowel and its accented
    counterpart) are grouped together in square brackets.

    Do not list uppercase counterparts of lowercase graphemes. If the
    orthography uses uppercase variants, deselect the Only Lowercase option
    below and the system will guess uppercase variants for the graphemes you
    have entered

    In order for the system to define mappings (and convert strings) between
    object language orthographies, all orthographies must have the exact same
    structure, i.e., the same number of graphemes and the same number of
    bracket groupings in the same order.

    For example, orthographies (2) and (1) have the same structure but
    orthographies (3) and (4) have unique structures.

    1. “[_a, _á], b, c, d”

    2. “[ae, áé], b, c, d”

    3. “ae, áé, b, c, d”

    4. “[ae, áé, àè], b, c, d”
    ###

