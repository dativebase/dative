define ['./resource'], (ResourceModel) ->

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

    resourceName: 'form'

    editableAttributes: []

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
    ]

    getValidator: (attribute) ->
      switch @activeServerType
        when 'FieldDB' then @getValidatorFieldDB attribute
        when 'OLD' then @getValidatorOLD attribute

    getValidatorOLD: (attribute) ->
      switch attribute
        when 'transcription' then @validOLDTranscription
        when 'translations' then @validOLDTranslations
        when 'date_elicited' then @validateOLDDateElicited
        else null

    validOLDTranscription: (value) ->
      @requiredString value

    validOLDTranslations: (value) ->
      error = null
      if (t for t in value when t.transcription.trim()).length is 0
        error = 'Please enter one or more translations'
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
        ( 0 [1-9] | 1 [0-2] )
        \/
        ( 0 [1-9] | 1 \d | 2 \d | 3 [01] )
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
      transcription: ""                 # <string>  (required, max length = 255)
      phonetic_transcription: ""        # <string>  (max length = 255)
      narrow_phonetic_transcription: "" # <string>  (max length = 255)
      morpheme_break: ""                # <string>  (max length = 255; sequence
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
      morpheme_gloss: ""                # <string>  (max length = 255; sequence
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
      status: ""                        # <string>  (max length = 40; indicates
                                        #            whether this is a form
                                        #            that has been elicited or
                                        #            whether it is one that
                                        #            needs to be elicited
                                        #            (i.e., is part of an
                                        #            elicitation plan); default
                                        #            value is "tested". Only other
                                        #            licit value is 'requries
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
      syntactic_category_string: ""     # <string>  (max length = 255; sequence
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

