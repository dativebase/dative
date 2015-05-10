define ['./resource'], (ResourceModel) ->

  # Language Model Model
  # --------------------
  #
  # A Backbone model for Dative language models.

  class LanguageModelModel extends ResourceModel

    resourceName: 'languageModel'

    ############################################################################
    # Language Model Schema
    ############################################################################

    # See:
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/lib/schemata.py#L1201-L1216
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/morphemelanguagemodel.py#L41-L66
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/controllers/morphemelanguagemodels.py

    defaults: ->

      name: ''
      description: ''
      corpus: null                # Corpus from which to extract the
                                  # morpheme-based N-grams.
      vocabulary_morphology: null # A morphology object from which a vocabulary
                                  # of 1-grams may be extracted.
      toolkit: 'mitlm'            # Name of the LM estimating toolkit;
                                  # currently the only possible value is
                                  # "mitlm".
      order: 3                    # bigram to quinquegram: integer between 2
                                  # and 5, defaults to 3.
      smoothing: ''               # The name of a smoothing algorithm that is
                                  # defined by the specified toolkit; for
                                  # "mitlm" these are 'ML', 'FixKN',
                                  # 'FixModKN', 'FixKNn', 'KN', 'ModKN', and
                                  # 'KNn'.
      categorial: ''              # Boolean (default is false); a categorial LM
                                  # scopes over morpheme categories whereas a
                                  # non-categorial one scopes over specific
                                  # morphemes.

      # Attributes that the OLD sends to us, but which the OLD will ignore if
      # we try to send them back.

      id: null                   # <int> relational id
      UUID: ''                   # <string> UUID
      enterer: null              # <object> attributes: `id`,
                                 # `first_name`, `last_name`,
                                 # `role`
      modifier: null             # <object> attributes: `id`,
                                 # `first_name`, `last_name`,
                                 # `role`
      datetime_entered: ""       # <string>  (datetime resource
                                 # was created/entered;
                                 # generated on the server as a
                                 # UTC datetime; communicated
                                 # in JSON as a UTC ISO 8601
                                 # datetime, e.g.,
                                 # '2015-02-11T10:50:57.821192'.)
      datetime_modified: ""      # <string>  (datetime resource
                                 # was last modified; format
                                 # and construction same as
                                 # `datetime_entered`.)
      generate_succeeded: false  # <boolean> will be true if server has
                                 # generated the LM.
      generate_message: ''       # <string> the message that the OLD returns
                                 # (indicating success or failure) after trying
                                 # to generate this LM.
      generate_attempt: ''       # <string> a UUID.
      perplexity: 0.0            # <number (float)> the perplexity of the LM's
                                 # corpus according to the LM. The OLD randomly
                                 # divides the corpus into training and test
                                 # sets multiple times and computes the
                                 # perplexity and returns the average.
      perplexity_attempt: ''     # <string> a UUID.
      perplexity_computed: false # <boolean> will be true if the server has
                                 # computed the perplexity of the LM.
      restricted: ''             # <boolean> if true, then only unrestricted
                                 # users can access this LM.
      morpheme_delimiters: ''    # a <string> of comma-separated morpheme
                                 # delimiters; defined in the OLD's application
                                 # settings.

    editableAttributes: [
      'name'
      'description'
      'corpus'
      'vocabulary_morphology'
      'toolkit'
      'order'
      'smoothing'
      'categorial'
    ]

    getValidator: (attribute) ->
      switch attribute
        when 'name' then @requiredString
        when 'corpus' then @requiredCorpus
        else null

    requiredCorpus: (value) ->
      error = null
      if @get('corpus').trim() is '' and not @get('rules_corpus')?
        error = 'You must either specify rules or a rules corpus'
      error

    manyToOneAttributes: [
      'lexicon_corpus'
      'rules_corpus'
    ]


