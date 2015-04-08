define ['./resource'], (ResourceModel) ->

  # Morphology Model
  # ---------------
  #
  # A Backbone model for Dative morphologies.

  class MorphologyModel extends ResourceModel

    resourceName: 'morphology'

    ############################################################################
    # Morphology Schema
    ############################################################################

    # See:
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/lib/schemata.py#L1136-L1152
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/morphology.py#L69-L91
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/controllers/morphologies.py

    # Validation:
    # A value for either rules or rules_corpus must be specified.

    defaults: ->
      name: ''                                   # <string> Required, unique
                                                 # among morphology names, max
                                                 # 255 chars.
      description: ''                            # <string> description of the
                                                 # morphology.
      lexicon_corpus: ''                         # <object> An OLD corpus model:
                                                 # received as an object, but
                                                 # OLD expects to receive an id.
      rules_corpus: ''                           # <object> An OLD corpus model:
                                                 # received as an object, but
                                                 # OLD expects to receive an id.
      script_type: ''                            # <string> forced choice; one of
                                                 # 'regex' or 'lexc'.
      extract_morphemes_from_rules_corpus: false # <boolean>. If true, then
                                                 # morphemes will be extracted
                                                 # from the rules corpus in
                                                 # addition to the default
                                                 # extraction from the lexicon
                                                 # corpus.
      rules: ''                                  # <string> Morphotactic rules:
                                                 # a string containing rules
                                                 # like "V-Agr".
      rich_upper: false                          # if True, the morphemes on
                                                 # the upper side of the tape
                                                 # are in <f|g|c> forma, else f
                                                 # format.
      rich_lower: false                          # if True, the morphemes on
                                                 # the lower side of the tape
                                                 # are in <f|g|c> forma, else f
                                                 # format
      include_unknowns: false                    # Boolean. If True, morphemes
                                                 # of unknown category will be
                                                 # added to lexicon.

      # Attributes that the OLD sends to us, but which the OLD will ignore if
      # we try to send them back.
      id: null                                   # <int> relational id
      UUID: ''                                   # <string> UUID
      enterer: null                              # <object> attributes: `id`,
                                                 # `first_name`, `last_name`,
                                                 # `role`
      modifier: null                             # <object> attributes: `id`,
                                                 # `first_name`, `last_name`,
                                                 # `role`
      datetime_entered: ""                       # <string>  (datetime resource
                                                 # was created/entered;
                                                 # generated on the server as a
                                                 # UTC datetime; communicated
                                                 # in JSON as a UTC ISO 8601
                                                 # datetime, e.g.,
                                                 # '2015-02-11T10:50:57.821192'.)
      datetime_modified: ""                      # <string>  (datetime resource
                                                 # was last modified; format
                                                 # and construction same as
                                                 # `datetime_entered`.)
      compile_succeeded: false                   # <boolean>. If true, then the
                                                 # server has successfully compiled the morphology.
      compile_message: ''                        # <string>. Explanation from
                                                 # the server about the outcome
                                                 # of the compile attempt.
      compile_attempt: ''                        # <string>. A UUID.
      generate_attempt: ''                       # <string>. A UUID.
      rules_generated: ''                        # <string>. Rules generated
                                                 # server-side from the
                                                 # rules_corpus.

    editableAttributes: [
      'name'
      'description'
      'lexicon_corpus'
      'rules_corpus'
      'script_type'
      'extract_morphemes_from_rules_corpus'
      'rules'
      'rich_upper'
      'rich_lower'
      'include_unknowns'
    ]

    getValidator: (attribute) ->
      switch attribute
        when 'name' then @requiredString
        when 'rules' then @rulesOrRulesCorpus
        when 'rules_corpus' then @rulesOrRulesCorpus
        else null

    rulesOrRulesCorpus: (value) ->
      error = null
      if @get('rules').trim() is '' and not @get('rules_corpus')?
        error = 'You must either specify rules or a rules corpus'
      error

    manyToOneAttributes: [
      'lexicon_corpus'
      'rules_corpus'
    ]

