define [
  './resource'
  './../utils/globals'
], (ResourceModel, globals) ->

  # Form Model
  # ---------------
  #
  # A Backbone model for Dative forms, i.e., OLD corpora.
  #
  # At present Dative `FormModel`s represent OLD corpora and have no
  # equivalent in the FieldDB data structure. They are called "forms"
  # because the term "corpora" is used for FieldDB corpora, which are different.

  class FormModel extends ResourceModel

    initialize: (attributes, options) ->
      super
      @setAttributesArrays()

    setAttributesArrays: ->
      if @activeServerType is 'OLD'
        @manyToOneAttributes = @manyToOneAttributesOLD
        @manyToManyAttributes = @manyToManyAttributesOLD
        @editableAttributes = @editableAttributesOLD

    resourceName: 'form'

    editableAttributes: []

    editableAttributesOLD: [
      'transcription'
      'phonetic_transcription'
      'narrow_phonetic_transcription'
      'morpheme_break'
      'grammaticality'
      'morpheme_gloss'
      'translations'
      'comments'
      'speaker_comments'
      'syntax'
      'semantics'
      'status'
      'elicitation_method'
      'syntactic_category'
      'speaker'
      'elicitor'
      'verifier'
      'source'
      'tags'
      'files'
      'date_elicited'
    ]

    manyToOneAttributes: []
    manyToManyAttributes: []

    manyToOneAttributesOLD: [
      'elicitation_method'
      'elicitor'
      'source'
      'speaker'
      'syntactic_category'
      'verifier'
    ]

    manyToManyAttributesOLD: [
      'tags'
      'files'
    ]

    getValidator: (attribute) ->
      switch @activeServerType
        when 'FieldDB' then @getValidatorFieldDB attribute
        when 'OLD' then @getValidatorOLD attribute

    getValidatorOLD: (attribute) ->
      switch attribute
        when 'transcription' then @requiredTranscriptionType
        when 'phonetic_transcription' then @requiredTranscriptionType
        when 'narrow_phonetic_transcription' then @requiredTranscriptionType
        when 'morpheme_break' then @requiredTranscriptionType
        when 'translations' then @validOLDTranslations
        when 'date_elicited' then @validateOLDDateElicited
        # The following validators are redundant when a FormAddWidgetView is
        # used because its field views have forced-choice select menus and
        # max-length inputs. But they do become necessary during CSV import.
        when 'grammaticality' then @inGrammaticalities
        when 'grammaticality' then @max255Chars
        when 'morpheme_gloss' then @max510Chars
        when 'syntax' then @max1023Chars
        when 'semantics' then @max1023Chars
        when 'status' then @inStatuses
        else null

    # Every form must have one of transcription, phonetic_transcription,
    # narrow_phonetic_transcription or morpheme_break.
    requiredTranscriptionType: (value) ->
      if (not @get('transcription').trim()) and
      (not @get('morpheme_break').trim()) and
      (not @get('phonetic_transcription').trim()) and
      (not @get('narrow_phonetic_transcription').trim())
        msg = 'Please enter a value in one of the following fields:
          transcription, morpheme break, phonetic transcription or narrow
          phonetic transcription'
        {
          transcription: msg
          morpheme_break: msg
          phonetic_transcription: msg
          narrow_phonetic_transcription: msg
        }
      else
        @max510Chars value

    # No longer being used now that we're using `requiredTranscriptionType`.
    validOLDTranscription: (value) ->
      result = @requiredString value
      if result is null
        @max255Chars value
      else
        result

    max255Chars: (value) ->
      if value.length > 255 then return '255 characters max'
      null

    max510Chars: (value) ->
      if value.length > 510 then return '510 characters max'
      null

    max1023Chars: (value) ->
      if value.length > 1023 then return '1023 characters max'
      null

    inStatuses: (value) ->
      if value in ['', 'tested', 'requires testing']
        null
      else
        'Only the values “tested” and “requires testing” are permitted'

    validOLDTranslations: (value) ->
      error = null
      if (t for t in value when t.transcription.trim()).length is 0
        error = 'Please enter one or more translations'
      error

    # The standard FormAddWidgetView prevents impossible grammaticalities but
    # the import interface makes it possible for the user to enter whatever
    # they want.
    inGrammaticalities: (value) ->
      error = null
      if value # '' for grammaticality is always ok
        if globals.oldApplicationSettings
          try
            grammaticalities =
              globals.oldApplicationSettings.get('grammaticalities').split(',')
            if value not in grammaticalities
              error = "Valid grammaticalities are: #{grammaticalities.join ', '}"
      error

    validateOLDDateElicited: (value) ->
      if value?.trim?() is ''
        null
      else
        if not @validDate value
          'Please enter a valid date in dd/mm/yyyy format'
        else
          null

    # Return `true` if `date` is a string in dd/mm/yyyy format. (Obviously
    # accepts some impossible dates, but shouldn't exclude any possible ones.)
    validDate: (date) ->
      date_regex = ///
        ^
        ( 0 [1-9] | 1 \d | 2 \d | 3 [01] )
        \/
        ( 0 [1-9] | 1 [0-2] )
        \/
        [0-2] \d{3}
        $
      ///
      date_regex.test date

    getValidatorFieldDB: (attribute) ->
      null

    ############################################################################
    # Form Schema
    ############################################################################

    defaults: ->
      activeServerType = @getActiveServerType()
      switch activeServerType
        when 'FieldDB' then @defaultFieldDBDatum()
        when 'OLD' then @defaultOLDForm()

    ############################################################################
    # FieldDB Datum Schema
    ############################################################################

    # Default FieldDB Datum

    # `@defaultFieldDBDatum` returns an object representing a default FieldDB
    # Datum (i.e., form). Note that most of the "meat" is in `datumFields`,
    # an array of objects.

    # The structure of each of these datum field object is as follows, where
    # the `label` and `value` are, in general, most important:

    #   defaultfield:        <boolean> (presumably indicates whether this is a
    #                                   "default" field or a "non-standard" one
    #                                   that a user has chosen to use)
    #   encryptedValue:      <string>  (= `value` unless encrypted, I think)
    #   fieldDBtype:         <string>  ("DatumField" is the standard value, I
    #                                   would think)
    #   help:                <string>  (help text, e.g., for an HTML title
    #                                   attribute)
    #   id:                  <string>  (usually equals `label`; I don't
    #                                   understand the difference; must be
    #                                   unique?)
    #   label:               <string>  (what kind of field this is, e.g.,
    #                                   `"utterance"`)
    #   labelFieldLinguists: <string>  (label for field linguists)
    #   mask:                <string>  (usually = `value` but when encrypted I
    #                                   think this is a more user-friendly
    #                                   hidden representation, e.g., "XXX-XX")
    #   shouldBeEncrypted:   <boolean> (whether the value should be encrypted)
    #   size:                <string>  (stringified integer; indicates the max
    #                                   length of the possible values?...)
    #   value:               <string>  (the value in the field; are values
    #                                   other than strings permitted?)
    #   version:             <string>  (the version of the client app (e.g.,
    #                                   Spreadsheet) or the FieldDB server? A
    #                                   string like "v2.38.16")

    # Note, however, that a `datumField` object can also have other attributes.
    # For example, the datum field with label `modifiedByUser` can have a `user`
    # attribute whose value is an object.

    # In fact, it's more complicated since some `datumField` objects have a very
    # different set of attributes. The datum fields of the ETI 3 Data Tutorial
    # corpus, for instance, has "label", "value", "mask", "encrypted",
    # "shouldBeEncrypted", "help", "showToUserTypes", and "userchooseable".

    # The labels of the default datum field objects are:

    #   judgement:          <string> (equivalent to OLD's `grammaticality`; oddly
    #                                 `grammatical` is sometimes a value here;
    #                                 "Grammaticality/acceptability judgement
    #                                 (*,#,?, etc). Leaving it blank can mean
    #                                 grammatical/acceptable, or you can choose a
    #                                 new symbol for this meaning.")
    #   utterance:          <string> (roughly equivalent to OLD's
    #                                 `transcription`; "Unparsed utterance in the
    #                                 language, in orthography or transcription.
    #                                 Line 1 in your LaTeXed examples for
    #                                 handouts. Sample entry: amigas")
    #   morphemes:          <string> (sequence of morpheme shapes and delimiters;
    #                                 equivalent to OLD's `morpheme_break`)
    #   gloss:              <string> (sequence of morpheme glosses and
    #                                 delimiters; equivalent to OLD's
    #                                 `morpheme_glosses`)
    #   translation:        <string> (no (enforced) conventions for multiple
    #                                 translations)
    #   tags:               <string> (tags; just a string with no enforced
    #                                 delimiter conventions, at least as far as I
    #                                 can tell)
    #   validationStatus:   <string> (status of the datum; note: setting to
    #                                 `"Deleted"` is what "deletes" a datum, I
    #                                 think. "For example: To be checked with a
    #                                 language consultant, Checked with Sebrina,
    #                                 Deleted etc...")
    #   syntacticCategory:  <string> (sequence of categories and delimiters,
    #                                 isomorphic with morphemes and gloss values,
    #                                 equivalent to OLD's
    #                                 syntactic_category_string)
    #   syntacticTreeLatex: <string> (tree in LaTeX Qtree bracket notation)
    #   enteredByUser:      <string> (a username; "The user who originally
    #                                 entered the datum")
    #   modifiedByUser:     <array>  (***Note: `value` is a string but `users` is
    #                                 the real value; it's an array of user objects
    #                                 each of which has four attributes:
    #                                   appVersion: "2.38.16.07.59ss Fri Jan 16
    #                                     08:02:30 EST 2015" #
    #                                   gravatar:
    #                                     "5b7145b0f10f7c09be842e9e4e58826d"
    #                                   timestamp: 1423667274803
    #                                   username: "jdunham")

    defaultFieldDBDatum: ->
      defaults =
        _id: ''                           # <string> (UUID generated by CouchDB.)
        _rev: ''                          # <string> (UUID with a "digit-"
                                          #           prefix; generated by
                                          #           CouchDB.)
        audioVideo: []                    # <array>  (of objects, I presume...)
        collection: 'datums'              # <string>
        comments: []                      # <array>  (of comment objects of form: {
                                          #             text: ''
                                          #             username: ''
                                          #             timestamp: ''}.)
        dateEntered: ''                   # <string> (timestamp in format
                                          #           2015-02-11T15:07:54.803Z.)
        dateModified: ''                  # <string> (timestamp in format
                                          #           2015-02-11T15:07:54.803Z.)
        datumFields:                      # <array>  (of objects, all of which
          @getCorpusDatumFields()         #           have `label` and `value`
                                          #           attributes, but others too.
                                          #           See above.)
        datumTags: []                     # <array>  (of objects, I presume ...)
        images: []                        # <array>  (of objects, I presume ...)
        jsonType: 'Datum'                 # <string>
        pouchname: ''                     # <string> (<username>-<corpus-name>,
                                          #           e.g., "jrwdunham-firstcorpus".)
        session: @defaultFieldDBSession() # <object> (representation of a(n
                                          #           elicitation) session; see
                                          #           `@defaultFieldDBSession()`
                                          #           below.)
        timestamp: null                   # <number> (Unix timestamp, e.g.,
                                          #           1423667274803)
      # We must clone the defaults otherwise we'll have multiple references to
      # the same mutable objects (e.g., arrays).
      result = @utils.clone defaults
      result

    # Return the datumFields of the currently active corpus, if applicable;
    # otherwise []. Cf. non-DRY `/views/base.coffee:getCorpusDatumFields`.
    getCorpusDatumFields: ->
      try
        globals.applicationSettings
          .get('activeFieldDBCorpusModel').get 'datumFields'
      catch
        []

    # Default FieldDB Session

    # `@defaultFieldDBSession` returns an object representing a default FieldDB
    # (elicitation) Session. Here the primary content is in the `sessionFields`
    # array of objects. Each session field object has the same keys (and value
    # types) as the datum field objects described above (except the `size`
    # attribute seems to be # missing).

    # The labels of the default session fields are:

    #   goal:         <string> (the goal of the elicitation session)
    #   consultants:  <string> (the consultant(s)/speaker(s) of the session)
    #   dialect:      <string> (the dialect of the consultant)
    #   language:     <string> (the language being elicited)
    #   dateElicited: <string> (when the elicitation session took place; format
    #                           YYY-MM-DD seen, but I don't know if this is
    #                           enforced)
    #   user:         <string> (username)
    #   dateSEntered: <string> (when the session was created; format "Mon Feb 02
    #                           2015 00:18:20 GMT-0800 (PST)" seen)

    defaultFieldDBSession: ->
      _id: ''                # <string> (UUID generated by CouchDB.)
      _rev: ''               # <string> (UUID with a "digit-"
      collection: 'sessions' # <string>
      comments: []           # <array>  (of comment objects of form: {
                             #             text: ''
                             #             username: ''
                             #             timestamp: ''}.)
      dateCreated: ''        # <string> (timestamp in format
                             #            2015-02-11T15:07:54.803Z.)
      dateModified: ''       # <string> (timestamp in format
                             #            2015-02-11T15:07:54.803Z.)
      lastModifiedBy: ''     # <string> (a username.)
      pouchname: ''          # <string> (<username>-<corpusname>, e.g.,
                             #           "jrwdunham-firstcorpus".)
      sessionFields: []      # <array>  (of objects, all of which have `label` and
                             #           `value` attributes, but others too. See
                             #           comments above.)
      title: ''              # <string> (concatenation of `dateElicited` and
                             #           `goal` values from `sessionFields`.)


    ############################################################################
    # FieldDB-specific getters
    ############################################################################


    # Datum Field getters
    ############################################################################

    # Return the datum field (an object) such that `label=label`.
    # E.g., `@getDatumField 'utterance'`.
    getDatumField: (label) ->
      try
        _.findWhere(@get('datumFields'), label: label)
      catch
        undefined

    # Return the value of `attribute` on the datum field (an object) such that
    # `label=label`. E.g., @getDatumFieldAttributeValue 'utterance', 'value'
    getDatumFieldAttributeValue: (label, attribute) ->
      @getDatumField(label)?[attribute]

    # Return the `value` value of the first object in `datumFields`
    # such that `label=label`.
    getDatumFieldValue: (label) ->
      @getDatumFieldAttributeValue label, 'value'

    # Get the `help` value of the first object in `datumFields`
    # such that `label=label`.
    getDatumFieldHelp: (label) ->
      @getDatumFieldAttributeValue label, 'help'


    # Session Field getters
    ############################################################################

    # Return the session field (an object) such that `label=label`.
    # E.g., `@getSessionField 'goal'`.
    getSessionField: (label) ->
      try
        _.findWhere(@get('session').sessionFields, label: label)
      catch
        undefined

    # Return the value of `attribute` on the session field (an object) such that
    # `label=label`.
    # E.g., @getSessionFieldAttributeValue 'goal', 'value'
    getSessionFieldAttributeValue: (label, attribute) ->
      @getSessionField(label)?[attribute]

    # Return the `value` value of the first object in `sessionFields`
    # such that `label=label`.
    getSessionFieldValue: (label) ->
      @getSessionFieldAttributeValue label, 'value'

    # Get the `help` value of the first object in `sessionFields`
    # such that `label=label`.
    getSessionFieldHelp: (label) ->
      @getSessionFieldAttributeValue label, 'help'


    # General Datum getters
    ############################################################################
    #
    # These methods are conveniences that try to treat a FieldDB datum as a
    # simple object. One passes in an "attribute" and these getters will return
    # a value by trying to find a match for that "attribute" in a datum/session
    # field label or by matching the "attribute" to a true attribute of the
    # datum.

    # Return `@attribute`, `@session.sessionFields(label=attribute)` or
    # `@datumFields(label=attribute)`, whichever exists first.
    getDatumValue: (attribute) ->
      directValue = @get attribute
      sessionField = @getSessionField attribute
      datumField = @getDatumField attribute
      _.filter([directValue, sessionField, datumField])[0]

    # Get the value of `subattr` of the value of the datum's `attribute`.
    # NOTE: this really only makes sense for session and datum fields, since
    # only these evaluate to true objects.
    # E.g., `@getDatumValueAttributeValue 'utterance', 'value'`
    getDatumValueAttributeValue: (attribute, subattr) ->
      try
        @getDatumValue(attribute)[subattr]
      catch
        undefined

    # Attempt to intelligently get the value of `attribute` in the datum,
    # where the value is not always `.value` and where `attribute` is
    # usually not really an attribute name.
    # Examples:
    # - `@getDatumValue 'utterance'` # a string (from datumFields)
    # - `@getDatumValue 'goal'`      # a string (from sessionFields)
    # - `@getDatumValue 'comments'`  # an array (a direct attribute)
    getDatumValueSmart: (attribute) ->
      datumValue = @getDatumValue attribute
      if @utils.type(datumValue) is 'object'
        if attribute is 'modifiedByUser'
          datumValue.users
        else
          datumValue.value
      else
        datumValue

    # Attempt to intelligently set the value of `attribute` in the datum,
    # Examples:
    # - `@getDatumValue 'utterance', 'chien'` # a string (into datumFields)
    # - `@getDatumValue 'comments', [...]`    # an array (a direct attribute)
    # NOTE: does not set to sessionFields (contrast with `getDatumValueSmart`
    # which does get from sessionFields, since we want these data points in
    # form display but we don't want to edit them via the form edit interface
    # (at least not yet we don't ...)
    setDatumValueSmart: (attribute, value) ->
      if typeof attribute is 'object'
        for key, value of attribute
          @_setDatumValueSmart key, value
      else
        @_setDatumValueSmart attribute, value

    _setDatumValueSmart: (attribute, value) ->
      if attribute in _.keys(@attributes)
        @set attribute, value
      else
        datumField = @getDatumField attribute
        if datumField
          oldValue = datumField.value
          if oldValue isnt value
            datumField.value = value
            datumField.mask = value
            @trigger 'change'

    # Get the `help` value of a FieldDB datum field or session field, if exists.
    getDatumHelp: (label) ->
      sessionFieldHelp = @getSessionFieldHelp label
      datumFieldHelp = @getDatumFieldHelp label
      _.filter([sessionFieldHelp, datumFieldHelp])[0]

    fieldDB2dative: (fieldDBDatum) ->
      @set 'id', fieldDBDatum.id
      @set fieldDBDatum.value

    # Return a representation of the model's state that FieldDB likes: just a
    # clone of the attributes with the `collection` removed.
    toFieldDB: ->
      result = _.clone @attributes
      # Not doing this causes a `RangeError: Maximum call stack size exceeded`
      # when cors.coffee tries to call `JSON.stringify` on a form model that
      # contains a forms collection that contains that same form model, etc. ad
      # infinitum.
      delete result.collection
      result

    # Return a representation of the model's state that FieldDB likes for
    # updating.
    toFieldDBForUpdate: ->
      resource = @toFieldDB()
      now = new Date()
      resource.dateModified = now.toISOString()
      resource.timestamp = now.valueOf()
      resource.pouchname = globals.applicationSettings.get 'activeFieldDBCorpus'
      resource.comments = (c for c in resource.comments when c.text)
      username = globals.applicationSettings.get 'username'
      gravatar = globals.applicationSettings.get 'gravatar'
      modifiedByUser = _.findWhere resource.datumFields, label: 'modifiedByUser'
      modifiedByUser.users = @utils.clone modifiedByUser.users
      modifiedByUser.users.push(
        username: username
        gravatar: gravatar
        timestamp: now.valueOf()
        appVersion: '' # TODO: how?
      )
      resource

    # Return a representation of the model's state that FieldDB likes for
    # creating.
    toFieldDBForCreate: ->
      resource = @toFieldDB()
      if 'id' of resource then delete resource.id
      if '_id' of resource then delete resource._id
      if '_rev' of resource then delete resource._rev
      if resource.session and not 'id' of resource.session
        delete resource.session
      now = new Date()
      resource.dateEntered = now.toISOString()
      resource.dateModified = now.toISOString()
      resource.timestamp = now.valueOf()
      resource.pouchname = globals.applicationSettings.get 'activeFieldDBCorpus'
      resource.comments = (c for c in resource.comments when c.text)
      username = globals.applicationSettings.get 'username'
      gravatar = globals.applicationSettings.get 'gravatar'
      enteredByUser = _.findWhere resource.datumFields, label: 'enteredByUser'
      enteredByUser.value = username
      enteredByUser.mask = username
      enteredByUser.user =
        username: username
        gravatar: gravatar
        appVersion: '' # TODO: how?
      resource

    ############################################################################
    # OLD Schema
    ############################################################################

    # `@defaultOLDForm` returns a default OLD form. For details on this schema,
    # see
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/form.py
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/model.py
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/lib/schemata.py#L289-L316

    # Note that the OLD *emits* relational attributes as JSON objects but it
    # *accepts* them *only* as integer ids. That is, a GET request for a form
    # will return an object whose `enterer` value is an object, e.g.,
    #
    #   "enterer": {"id": 37, "first_name": "Joel", ...},
    #
    # but PUT and POST requests to update/add a form *must* valuate their
    # relational attributes as integer ids only, e.g.,
    #
    #   "enterer": 1,

    # Note that some attributes are commented-out below. This is because these
    # attributes are valuated server-side and should not have client-side
    # defaults. That is, the OLD will send them to us, but we cannot directly
    # modify them on the server with a PUT/POST request. Nevertheless, it is
    # useful to describe their properties here.

    # For a complete list of the attributes that can be specified when
    # creating/updating an OLD form, see
    # https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/lib/schemata.py#L289-L316

    defaultOLDForm: ->
      # These are the attributes that the OLD will recognize on POST/PUT
      # (create/update) requests; others *can* be supplied, but the OLD will
      # ignore them. The "REC TYPE" header indicates the data type that the OLD
      # sends to us. The notes indicate the type that the OLD expects to
      # receive, if different.

      # ATTRIBUTE                         EXP TYPE  NOTES & VALIDATION
      transcription: ""                 # <string>  (max length = 510)
      phonetic_transcription: ""        # <string>  (max length = 510)
      narrow_phonetic_transcription: "" # <string>  (max length = 510)
      morpheme_break: ""                # <string>  (max length = 510; sequence
                                        #            of morpheme shapes and
                                        #            delimiters; equivalent to
                                        #            FieldDB `morphemes`.)
      grammaticality: ""                # <string>  (max length = 255;
                                        #            grammaticality judgment;
                                        #            note that the OLD stores
                                        #            possible values in
                                        #            server-side
                                        #            application_settings
                                        #            resources.)
      morpheme_gloss: ""                # <string>  (max length = 510; sequence
                                        #            of morpheme glosses and
                                        #            delimiters; # equivalent
                                        #            to FieldDB `gloss`.)
      translations: []                  # <array>   (of objects, each of which
                                        #            represents a translation,
                                        #            with keys for
                                        #            `transcription` and
                                        #            `grammaticality`, the
                                        #            latter being more
                                        #            correctly labeled
                                        #            `acceptibility`. *WARN*:
                                        #            the OLD currently requires
                                        #            every form to have at
                                        #            least one
                                        #            `translation.transcription`
                                        #            value and all
                                        #            `translation.grammaticality`
                                        #            values must be present in
                                        #            `application_settings.grammaticalities`.)
      comments: ""                      # <string>  (general notes about the
                                        #            form.)
      speaker_comments: ""              # <string>  (comments by the
                                        #            speaker/consultant.)
      syntax: ""                        # <string>  (max length = 1023; assumed
                                        #            this would be a PTB tree,
                                        #            but no logic yet attached
                                        #            to that assumption.)
      semantics: ""                     # <string>  (max length = 1023; intended
                                        #            for formal semantic
                                        #            denotations.)
      status: "tested"                  # <string>  (max length = 40; indicates
                                        #            whether this is a form
                                        #            that has been elicited or
                                        #            whether it is one that
                                        #            needs to be elicited
                                        #            (i.e., is part of an
                                        #            elicitation plan); default
                                        #            value is "tested". Only other
                                        #            licit value is 'requires
                                        #            testing'. See https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/lib/utils.py#L1483.
                                        #            Similar to
                                        #            `validationStatus` in
                                        #            FieldDB.)
      elicitation_method: null          # <object>  (method by which the form
                                        #            was elicited;
                                        #            received as an object,
                                        #            returned as an integer id.)
      syntactic_category: null          # <object>  (category of the form;
                                        #            received as an object,
                                        #            returned as an integer id.)
      speaker: null                     # <object>  (speaker/consultant who
                                        #            produced/judged the form;
                                        #            received as an object,
                                        #            returned as an integer id.)
      elicitor: null                    # <object>  (elicitor of the form;
                                        #            received as an object,
                                        #            returned as an integer id.)
      verifier: null                    # <object>  (user who has "verified"
                                        #            quality/accuracy of the
                                        #            form; received as an
                                        #            object, returned as an
                                        #            integer id.)
      source: null                      # <object>  (textual source (e.g.,
                                        #            research paper, book of
                                        #            texts, pedagogical
                                        #            material, etc.) of the
                                        #            form, if applicable;
                                        #            received as an object,
                                        #            returned as an integer id.)
      tags: []                          # <array>   (of objects, each of which
                                        #            represents a tag that is
                                        #            associated to this form.
                                        #            Note: sent by OLD as an
                                        #            array of objects but must
                                        #            be received as an array of
                                        #            integer ids.)
      files: []                         # <array>   (of objects, each of which
                                        #            represents a file that is
                                        #            associated to this form.
                                        #            Note: sent by OLD as an
                                        #            array of objects but must
                                        #            be received as an array of
                                        #            integer ids.)
      date_elicited: ""                 # <string>  (date elicited; OLD sends
                                        #            it in ISO 8601 format, i.e.,
                                        #            "YYYY-MM-DD" but expects
                                        #            to receive it in
                                        #            "MM/DD/YYYY" format.)

      # These are attributes that the OLD sends to us, but will ignore if we try
      # to send them back. The "REC TYPE" column header indicates the type of
      # value that we can expect to receive from the OLD.

      # ATTRIBUTE                         REC TYPE  NOTES & VALIDATION
      id: null                          # <integer> (created by RDBMS on server)
      UUID: ""                          # <string>  (UUID created by the server;
                                        #            used to link forms with
                                        #            their deleted/premodified
                                        #            copies)
      datetime_entered: ""              # <string>  (datetime form was
                                        #            created/entered; generated
                                        #            on the server as a UTC
                                        #            datetime; communicated in
                                        #            JSON as a UTC ISO 8601
                                        #            datetime, e.g.,
                                        #            '2015-02-11T10:50:57.821192'.)
      datetime_modified: ""             # <string>  (datetime form was last
                                        #            modified; format and
                                        #            construction same as
                                        #            `datetime_entered`.)
      syntactic_category_string: ""     # <string>  (max length = 510; sequence
                                        #            of morpheme categories and
                                        #            delimiters; isomorphic to
                                        #            `morpheme_break` and
                                        #            `morpheme_gloss` values;
                                        #            equivalent to FieldDB
                                        #            `syntacticCategory`.
                                        #            *WARN*: the OLD currently
                                        #            only constructs this
                                        #            server-side and does *not*
                                        #            allow for it to be
                                        #            user-specified; it may be
                                        #            desirable to change this.)
      morpheme_break_ids: []            # <array>   (array of arrays encoding
                                        #            the cross-references
                                        #            between morpheme shapes
                                        #            in the `morpheme_break`
                                        #            value and lexical forms in
                                        #            the database.)
      morpheme_gloss_ids: []            # <array>   (array of arrays encoding
                                        #            the cross-references
                                        #            between morpheme glosses
                                        #            in the `morpheme_break`
                                        #            value and lexical forms in
                                        #            the database.)
      break_gloss_category: ""          # <string>  (serialized zip of the
                                        #            `morpheme_break`,
                                        #            `morpheme_gloss`, and
                                        #            `syntactic_category_string`
                                        #            values; e.g.,
                                        #            "chien|dog|N-s|PL|Num".)
      enterer: null                     # <object>  (enterer of the form.)
      modifier: null                    # <object>  (last user to modify the form.)
      collections: []                   # <array>   (of objects, each of which
                                        #            represents a collection
                                        #            that this form belongs to.
                                        #            Note: emitted but not
                                        #            received by the OLD; use
                                        #            the `collections`
                                        #            interface to manipulate
                                        #            collection membership.)


    ############################################################################
    # FieldDB-specific DELETE/DESTROY stuff.
    ############################################################################

    # To destroy a FieldDB datum, you do a PUT request where
    # `.trashed='deleted'`.

    destroyResourceOnloadHandler: (responseJSON, xhr) ->
      switch globals.applicationSettings.get('activeServer').get('type')
        when 'OLD'
          super responseJSON, xhr
        when 'FieldDB'
          @destroyResourceOnloadHandlerFieldDB responseJSON, xhr

    destroyResourceOnloadHandlerFieldDB: (responseJSON, xhr) ->
      Backbone.trigger "destroy#{@resourceNameCapitalized}End"
      if xhr.status is 201 and responseJSON.ok is true
        Backbone.trigger "destroy#{@resourceNameCapitalized}Success", @
      else
        error = responseJSON.error or 'No error message provided.'
        Backbone.trigger "destroy#{@resourceNameCapitalized}Fail", error
        console.log "Request to delete FieldDB datum #{@get 'id'} failed
          (status not 201)."
        console.log error

    getDestroyResourceHTTPMethod: ->
      switch globals.applicationSettings.get('activeServer').get('type')
        when 'OLD' then super
        when 'FieldDB' then 'PUT'

    getDestroyResourceURL: ->
      switch globals.applicationSettings.get('activeServer').get('type')
        when 'OLD' then super
        when 'FieldDB' then @getDestroyResourceURLFieldDB()

    # Returns a URL for deleting a resource on a FieldDB web service.
    # NOTE: you don't really delete FieldDB datums and you don't make a DELETE
    # HTTP request; you just set the `trashed` attribute to "deleted".
    # PUT <corpus_url>/<pouchname>/<datum_id>?rev=<datum_rev>
    getDestroyResourceURLFieldDB: ->
      url = globals.applicationSettings.get 'baseDBURL'
      pouchname = globals.applicationSettings.get 'activeFieldDBCorpus'
      "#{url}/#{pouchname}/#{@get '_id'}?rev=#{@get '_rev'}"

    getDestroyResourcePayload: ->
      switch globals.applicationSettings.get('activeServer').get('type')
        when 'OLD' then super
        when 'FieldDB' then @getDestroyResourcePayloadFieldDB()

    # Return the payload for deleting a FieldDB datum: here I use the same
    # object used to update a datum, except I add `datum.trashed='deleted'`.
    getDestroyResourcePayloadFieldDB: ->
      payload = @toFieldDBForUpdate()
      payload.trashed = 'deleted'
      payload

    # Destroy an OLD form.
    # DELETE `<OLD_URL>/forms/<form.id>`
    # TODO: I think I can safely delete this since `destroyResource` in the
    # super class is doing what this used to.
    destroyOLDForm: (options) ->
      Backbone.trigger 'destroyOLDFormStart'
      @constructor.cors.request(
        method: 'DELETE'
        url: "#{@getOLDURL()}/forms/#{@get 'id'}"
        onload: (responseJSON, xhr) =>
          Backbone.trigger 'destroyOLDFormEnd'
          if xhr.status is 200
            Backbone.trigger 'destroyOLDFormSuccess', @
          else
            error = responseJSON.error or 'No error message provided.'
            Backbone.trigger 'destroyOLDFormFail', error
            console.log "DELETE request to /forms/#{@get 'id'} failed (status not 200)."
            console.log error
        onerror: (responseJSON) =>
          Backbone.trigger 'destroyOLDFormEnd'
          error = responseJSON.error or 'No error message provided.'
          Backbone.trigger 'destroyOLDFormFail', error
          console.log "Error in DELETE request to /forms/#{@get 'id'}
            (onerror triggered)."
      )

    ############################################################################
    # HISTORY.
    ############################################################################

    fetchHistory: ->
      switch @activeServerType
        when 'OLD' then @fetchHistoryOLD()
        when 'FieldDB' then @fetchHistoryFieldDB()

    # GET /forms/<id>/history
    # If successful, returns `{"form": { ... }, "previous_versions": [ ... ]}`
    fetchHistoryOLD: ->
      @trigger 'fetchHistoryFormStart'
      @constructor.cors.request(
        method: 'GET'
        url: "#{@getOLDURL()}/forms/#{@get 'id'}/history"
        onload: (responseJSON, xhr) =>
          @trigger 'fetchHistoryFormEnd'
          if xhr.status is 200
            @trigger 'fetchHistoryFormSuccess', responseJSON
          else
            error = responseJSON.error or 'No error message provided.'
            @trigger 'fetchHistoryFormFail', error
            console.log "GET request to /forms/#{@get 'id'}/history failed (status not 200)."
            console.log error
        onerror: (responseJSON) =>
          @trigger 'fetchHistoryFormEnd'
          error = responseJSON.error or 'No error message provided.'
          @trigger 'fetchHistoryFormFail', error
          console.log "Error in GET request to /forms/#{@get 'id'}/history
            (onerror triggered)."
      )

    # Request the history of the form model, the user can click on a revision
    # and see the details preferably by simply showing the other revision as a
    # model along side in the same views
    fetchHistoryFieldDB: ->
      console.log "you want to fetch the history of OLD form #{@get 'id'}"
      console.log (new FieldDB.FieldDBObject()).version
      console.log 'FieldDB.Datum'
      console.log FieldDB.Datum
      console.log @id
      fielddbHelperModel = new FieldDB.Datum(_id: @id)
      console.log 'got fielddbHelperModel'
      console.log fielddbHelperModel
      console.log 'fielddbHelperModel.fetchRevisions()'
      console.log fielddbHelperModel.fetch_revisions
      fielddbHelperModel.fetch_revisions().then(
          (revisions) ->
            # TODO: not sure we want to set this on the model ...
            # TODO can we avoid fetching them until the user clicks on the one they want?
            console.log 'got revisions'
            console.log revisions
            previousVersions = revisions.map((revisionUrl) -> url: revisionUrl)
            console.log 'got previousVersions'
            console.log previousVersions
            @set 'previousVersions', previousVersions
        ,
          (error) ->
            console.log 'TODO how do you talk to users about errors contacting
              the server etc...', error
      ).fail(
        (error) ->
          console.log 'TODO how do you talk to users about errors contacting
            the server etc...', error
      )

