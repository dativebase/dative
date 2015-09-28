define ['./resource'], (ResourceModel) ->

  # Language Model
  # --------------
  #
  # A Backbone model for Dative languages. These are ISO 639-3 language
  # objects. They are not user-editable.

  class LanguageModel extends ResourceModel

    resourceName: 'language'

    ############################################################################
    # Language Schema
    ############################################################################

    defaults: ->
      Id: ''                # <string>, 3-char unique id for language.
      Part2B: ''            # <string>, 3 chars.
      Part2T: ''            # <string>, 3 chars.
      Part1: ''             # <string>, 2 chars.
      Scope: ''             # <string>, 1 char.
      Type: ''              # <string>, 1 char.
      Ref_Name: ''          # <string>, max 150 chars; this is the
                            # reference name, i.e., the name for the language
                            # that the Ethnologue (arbitrarily?) chose as the
                            # standard one.
      Comment: ''           # <string>, max 150 chars.
      datetime_modified: '' # <datetime>

    editableAttributes: []

