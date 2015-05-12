define ['./resource'], (ResourceModel) ->

  # morphological parser Model
  # --------------------
  #
  # A Backbone model for Dative morphological parsers.

  class MorphologicalParserModel extends ResourceModel

    resourceName: 'morphologicalParser'
    serverSideResourceName: 'morphologicalparsers'

    ############################################################################
    # morphological parser Schema
    ############################################################################

    # See:
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/lib/schemata.py#L1201-L1216
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/morphologicalparser.py#L145-L166
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/controllers/morphologicalparsers.py

    defaults: ->

      name: ''                    # <string>
      description: ''             # <string>
      phonology: null             # <int id>/<object> a phonology resource.
      morphology: null            # <int id>/<object> a morphology resource.
      language_model: null        # <int id>/<object> a language model resource.

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
                                 # generated the parser.
      generate_message: ''       # <string> the message that the OLD returns
                                 # (indicating success or failure) after trying
                                 # to generate this parser.
      generate_attempt: ''       # <string> a UUID.
      compile_succeeded: false   # <boolean> will be true if server has
                                 # compiled the parser.
      compile_message: ''        # <string> the message that the OLD returns
                                 # (indicating success or failure) after trying
                                 # to compile this parser.
      compile_attempt: ''        # <string> a UUID.

    editableAttributes: [
      'name'
      'description'
      'phonology'
      'morphology'
      'language_model'
    ]

    getValidator: (attribute) ->
      switch attribute
        when 'name' then @requiredString
        when 'phonology' then @requiredPhonology
        when 'morphology' then @requiredMorphology
        when 'language_model' then @requiredLanguageModel
        else null

    requiredPhonology: (value) ->
      error = null
      if _.isEmpty @get('phonology')
        error = 'You must specify a phonology when creating a morphological
          parser'
      error

    requiredMorphology: (value) ->
      error = null
      if _.isEmpty @get('morphology')
        error = 'You must specify a morphology when creating a morphological
          parser'
      error

    requiredLanguageModel: (value) ->
      error = null
      if _.isEmpty @get('language_model')
        error = 'You must specify a language model when creating a morphological
          parser'
      error

    manyToOneAttributes: [
      'phonology'
      'morphology'
      'language_model'
    ]

