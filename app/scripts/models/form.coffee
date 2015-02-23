define [
    'underscore'
    'backbone'
    './../utils/globals'
    './database'
    './base'
  ], (_, Backbone, globals, database, BaseModel) ->

  # Form Model
  # ----------
  #
  # A Backbone model for Dative forms.
  #
  # A Dative form model can either have the structure of a FieldDB datum or
  # that of an OLD form. See `@defaultFieldDBDatum` and `@defaultOLDForm` for a
  # full specification of each of these data structures.

  class FormModel extends BaseModel

    url: 'fakeurl' # Backbone throws 'A "url" property or function must be
                   # specified' if this is not present.

    getActiveServerType: ->
      globals.applicationSettings.get('activeServer').get 'type'


    ############################################################################
    # Questions & TODOs
    ############################################################################

    # - datumTags:
    #   - @cesine: I don't know what to do with this attribute... Is it only
    #     used in the Prototype?
    # - comments (in FieldDB):
    #   - Why do fieldDBComments have timestampModified values when they can't
    #     be modified? At least, they can't be modified in Spreadsheet.


    ############################################################################
    # Dative Schema (differs depending on server type: FieldDB or OLD)
    ############################################################################

    defaults: ->
      if @getActiveServerType() is 'FieldDB'
        @defaultFieldDBDatum()
      else
        @defaultOLDForm()


    ############################################################################
    # FieldDB Schema
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
        datumField.value = value

    # Get the `help` value of a FieldDB datum field or session field, if exists.
    getDatumHelp: (label) ->
      sessionFieldHelp = @getSessionFieldHelp label
      datumFieldHelp = @getDatumFieldHelp label
      _.filter([sessionFieldHelp, datumFieldHelp])[0]


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
                                        #            "YYYY-MM-DD" but receives it
                                        #            in "MM/DD/YYYY" format.)

      # These are attributes that the OLD send to us, but will ignore if we try
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

    # Schema of a user object as the OLD would send it to us.
    # Cf. https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/model.py#L44
    defaultUserFromOLD: ->
      id: null
      first_name: null
      last_name: null
      role: null

    # Schema of a speaker object as the OLD would send it to us.
    # Cf. https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/model.py#L40
    defaultSpeakerFromOLD: ->
      id: null
      first_name: null
      last_name: null
      dialect: null

    # Schema of an elicitation method object as the OLD would send it to us.
    # Cf. https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/model.py#L31
    defaultElicitationMethodFromOLD: ->
      id: null
      name: null

    # Schema of a syntactic category object as the OLD would send it to us.
    # Cf. https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/model.py#L41
    defaultSyntacticCategoryFromOLD: ->
      id: null
      name: null

    # Schema of a source object as the OLD would send it to us.
    # Note that the data structure here is that of BibTeX.
    # Cf. https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/model.py#L38-L39
    defaultSourceFromOLD: ->
      id: null
      type: null
      key: null
      journal: null
      editor: null
      chapter: null
      pages: null
      publisher: null
      booktitle: null
      school: null
      institution: null
      year: null
      author: null
      title: null
      node: null


    ############################################################################
    # FieldDB-to-Dative Schema stuff
    # TODO: deprecate/remove this
    ############################################################################

    # FieldDb to Dative: input: a FieldDB datum object, output: a Dative form model
    # --------------------------------------------------------------------------

    fieldDB2dative: (fieldDBDatum) ->
      # A FieldDB Datum is, at its core, an array of objects, each of which has
      # a `label` and a `value` attribute. This method essentially creates a new
      # object from that label/value information. Certain labels are changed.
      # The entire fieldDBDatum is stored in the newly created Dative model under
      # the attribute `fieldDBDatum` so that other # attributes (i.e., `mask`,
      # `encrypted`, `shouldBeEncrypted`, `help`, `size`, and
      # `userchooseable` can be recovered).

      @set 'id', fieldDBDatum.id
      @set fieldDBDatum.value

    # Converts attribute names and values, as appropriate. Also stores the
    # FieldDB datum object unmodified in an attribute.
    #
    # TODO:
    #
    # - dative2fieldDB
    # - old2dative
    # - dative2old
    #
    # TODO: answer these questions (w/ help from @cesine):

    # 1. datumField.tags is simply a string. Do the current FieldDB
    # applications make any assumptions about how tags are identified within
    # that string? I am assuming that it's just a string and the exectation
    # is that users will use whatever tag-delimiting conventions they like.
    # In the OLD, a tag can have a name that has whitespace in it. An OLD tag
    # is an object with `name`, `id`, and `description` attributes. Do we want
    # to modify the FieldDB data structure to allow for these types of tags?
    # For now I am renaming FieldDB tags as `fieldDBTags` on Dative and I will
    # treat FieldDB and OLD tags differently.

    # 2. What to do with `datumField.validationStatus`? Is it the equivalent of
    # the OLD's `status`? Since both are strings, I am (for now) treating them
    # both as `status` fields in Dative.

    # 3. What to do with `datumStates`? It is an array of objects with 4
    # attributes: `color`, `showInSearchResults`, `selected`, and `state`. I am
    # currently not using this attribute in Dative.

    # 4. `datumField.syntacticCategory` is actually a segmented list of
    # categories corresponding to each morpheme in the morphemeBreak, at
    # least that is what I glean it should be from the `help` value for this
    # field. In my opinion, this field is misnamed, as is "gloss". Both
    # should be plural: "syntacticCategories" and "glosses" since they are
    # really sequences of categories and glosses. Consequently,
    # "syntacticCategory" should be given to the category of the entire
    # datum/form, as in the OLD. I am renaming both
    # `FieldDB.Datum.syntacticCategory` and
    # `OLD.Form.syntacticCategoryString` to `Dative.Form.syntacticCategories`.
    # `OLD.Form.syntacticCategory` is `Dative.Form.syntacticCategory` and
    # there is, as of yet, no equivalent in FieldDB.

    # 5. `datumField.syntacticTreeLaTeX`. I'm just leaving this as is for now.
    # The OLD assumes (implicitly) that the values of its `syntax` attributes
    # will be PTB-style bracket notation trees. Dative should be able to do
    # stuff with both. My current approach is for Dative to rename
    # `OLD.Form.syntax` to `Dative.Form.syntacticTreePTB` and to adopt
    # `FieldDB.datumField.syntacticTreeLaTeX` as
    # `Dative.Form.syntacticTreeLaTeX`. That is, the two syntax bracket
    # notation fields will co-exist, for now. (Even though you can easily get
    # from PTB trees to QTree/LaTeX ones as I do in the OLD web app ...)

    # 6. `datumField.`modifiedByUser` is an array of all users who have modified
    # the form. This is odd because it's useful to know the order of who modified
    # it. The OLD stores all of this information: who made what modification when.
    # (In the OLD, `modifier` is an object representing the user to make the last
    # modification. Previous modifiers can be retrieved by retrieving the history
    # of a form.) Is the `modifiedByUser` array ordered? Is there a way to
    # recover the modification history from the corpus service so that we can
    # provide a "get history" feature? For now I am having Dative use both
    # FieldDB's `modifiedByUser` and the OLD's `modifier` and Dative will treat
    # them differently.

    # 7. What is the difference between `datumTags` and `datumFields.tags`?
    # Looks to me like the latter isn't being used by the Spreadsheet app: it
    # uses the former. I am taking FieldDB `tags` as `fieldDBTags` and
    # FieldDB `datumTags` as `fieldDBDatumTags`. OLD `tags` will be `tags`,
    # for now...

    # 8. `comments` is an array. I think that the OLD and FieldDB are using the
    # word "comments" in two different ways. In the OLD, "comments" is just a
    # string of comments by the creator/editor of the form about the form. In
    # FieldDB, "comments" is an array of comments made by various users about
    # the form. Thus a user might only have the "Commenter" role on a corpus
    # and may be allowed to add comments but not do much else. For now I am
    # renaming `FieldDB.Datum.comments` to `Dative.Form.fieldDBComments`.

    # 9. I am renaming FieldDB `utterance` to Dative `transcription`. In the
    # OLD, `transcription` is by default and implicitly an orthographic
    # transcription. However, `Orthography` is another field option in some
    # FieldDB GUIs. The OLD has specific `phoneticTranscription` and
    # `narrowPhoneticTranscription` fields. Not clear to me just yet how we
    # should deal with these various similar fields. The logic around all of
    # these fields should be the same/ similar, i.e., in terms of IGT
    # formatting.

    fieldDB2dative_: (fieldDBDatum) ->
      # A FieldDB Datum is, at its core, an array of objects, each of which has
      # a `label` and a `value` attribute. This method essentially creates a new
      # object from that label/value information. Certain labels are changed.
      # The entire fieldDBDatum is stored in the newly created Dative model under
      # the attribute `fieldDBDatum` so that other # attributes (i.e., `mask`,
      # `encrypted`, `shouldBeEncrypted`, `help`, `size`, and
      # `userchooseable` can be recovered).

      dativeForm =
        id: fieldDBDatum.id
        fieldDBDatum: fieldDBDatum
        fieldDBComments: fieldDBDatum.value.comments # (an array)
        datetimeModified: @fixFieldDBDatetimeString(
          fieldDBDatum.value.dateModified) # a string datetime (with timezone)
        datetimeEntered: @fixFieldDBDatetimeString(
          fieldDBDatum.value.dateEntered) # a string datetime (with timezone)

      datumFields = fieldDBDatum.value.datumFields
      sessionFields = fieldDBDatum.value.session.sessionFields
      for fieldDBObject in datumFields.concat sessionFields

        # Here is where the label renaming and value conversion occurs
        attribute = @fieldDBAttribute2datumAttribute fieldDBObject.label
        value = @fieldDBValue2datumValue(fieldDBObject, fieldDBObject.label)

        # An array value in a fieldDB datumField might (?) be encoded as
        # multiple objects with the same `label` value.
        # TODO @cesine: does this ever happen? I.e., can `datumFields` contain
        # two objects with the same `label` value?
        if dativeForm[attribute] and
        @utils.type(dativeForm[attribute]) is 'array'
          dativeForm[attribute].push value
        else
          dativeForm[attribute] = value

      @set dativeForm

    # Transform FieldDB values to Dative-style ones.
    # NOTE: label is the *unmodified* FieldDB datum label.
    fieldDBValue2datumValue: (object, label) ->
      value = object.value
      switch label
        when 'translation' then @fieldDBTranscription2dativeTranscriptions value
        when 'user' then @fieldDBUsername2dativeUser value
        when 'enteredByUser' then @fieldDBUsername2dativeUser value
        when 'modifiedByUser' then object.users
        else value

    fieldDBTranscription2dativeTranscriptions: (value) ->
      [{appropriateness: '', transcription: value}]

    # This converts a value which is simply a username (a string) to a
    # Dative-style user object with a single valuated attribute: `username`.
    # This applies to `sessionFields.user` and `datumFields.enterer`.
    fieldDBUsername2dativeUser: (value) ->
      enterer = @defaultUserFromOLD()
      enterer.username = value
      enterer

    fieldDBAttribute2datumAttribute: (label) ->
      switch label
        when 'utterance' then 'transcription'
        when 'gloss' then 'morphemeGloss'
        when 'morphemes' then 'morphemeBreak'
        when 'judgement' then 'grammaticality'
        when 'translation' then 'translations'
        when 'syntacticCategory' then 'syntacticCategories' # see question #4 above.
        when 'validationStatus' then 'status' # @cesine: which statuses are relevant to the logic of the various FieldDB GUIs?
        when 'user' then 'sessionEnterer'
        when 'enteredByUser' then 'enterer'
        when 'modifiedByUser' then 'modifiers'
        when 'tags' then 'fieldDBTags'
        when 'datumTags' then 'fieldDBDatumTags'
        else label

    # For some reason *some* FieldDB datetimes are enclosed in double quotation
    # marks. This fixes that.
    fixFieldDBDatetimeString: (datetimeString) ->
      try
        datetimeString.replace /(^"|"$)/g, ''
      catch
        datetimeString


    ############################################################################
    # OLD-to-Dative Schema stuff
    # TODO: deprecate/remove this
    ############################################################################

    old2dative: (oldForm) ->
      @set oldForm

    # Convert an OLD form object to a Dative form object.
    # An OLD form is received as a JSON object. See
    # http://online-linguistic-database.readthedocs.org/en/latest/datastructure.html#form
    # for an exact specification of its attributes and their validation
    # requirements.
    old2dative_: (oldForm) ->
      dativeForm = {}
      for attribute, value of oldForm
        attribute = @oldAttribute2datumAttribute attribute
        value = @oldValue2datumValue value
        dativeForm[attribute] = value
      dativeForm

    # camelCase-ify the attributes of an OLD object, and perform some
    # idiosyncratic changes.
    oldAttribute2datumAttribute: (attribute) ->
      switch attribute
        when 'syntactic_category_string' then 'syntacticCategories'
        when 'syntax' then 'syntacticTreePTB'
        else @utils.snake2camel attribute

    # The values of an OLD form object can themselves be objects. In that case,
    # to Dative-ize them we change their snake_case attributes to camelCase.
    oldValue2datumValue: (value) ->
      if @utils.type(value) is 'object'
        newValue = {}
        for attribute, subValue of value
          newValue[@utils.snake2camel(attribute)] = subValue
        newValue
      else
        value

    # The OLD serves a form as a JSON object. The `Form.get_dict()` method is responsible
    # for transforming a form-as-python-object to a JSON object of the following form:
    # Relational data are truncated, e.g., form_dict['elicitor'] is a dict with keys for
    # 'id', 'first_name' and 'last_name' (cf. get_mini_user_dict above) and lacks
    # keys for other attributes such as 'username', 'personal_page_content', etc.
    oldJSON:
      id: null
      UUID: null
      transcription: null
      phonetic_transcription: null
      narrow_phonetic_transcription: null
      morpheme_break: null
      morpheme_gloss: null
      comments: null
      speaker_comments: null
      grammaticality: null
      date_elicited: null # ISO date string, e.g., "2014-07-25"
      datetime_entered: null # ISO datetime string, e.g., "2014-07-25T00:21:02.066819"
      datetime_modified: null # ISO datetime string, e.g., "2014-07-25T00:21:02.066819"
      syntactic_category_string: null # E.g., "N-Num"

      # morpheme_break_ids and morpheme_gloss_ids are nested arrays with depth of 4
      # a possible morpheme_break_ids value for a form like 'chiens' could be
      # [[[[33, u'dog', u'N']], [[111, u'PL', u'Num'], [103, u'PL', u'Agr']]]]
      # The outermost array represents the form; the arrays within the form array are
      # word arrays; each word array contains one or more morpheme arrays; finally, each
      # morpheme may be ambiguous so it may contain multiple triplet arrays representing
      # references to matching lexical forms. Morpheme triplets are [id, gloss, category]
      # for `morpheme_break_ids` and [id, shape, category] for `morpheme_gloss_ids`.
      morpheme_break_ids: []
      morpheme_gloss_ids: []

      break_gloss_category: null # E.g., "chien|dog|N-s|PL|Num"

      syntax: null
      semantics: null
      status: null

      elicitor: @defaultOLDJSONUser
      enterer: @defaultOLDJSONUser
      modifier: @defaultOLDJSONUser
      verifier: @defaultOLDJSONUser
      speaker: @defaultOLDJSONSpeaker
      elicitation_method: @defaultOLDJSONElicitationMethod
      syntactic_category: @defaultOLDJSONSyntacticCategory
      source: @defaultOLDJSONSource

      translations: [] # List of objects with the following attributes: "id", "transcription", "grammaticality"
      tags: [] # List of objects with the following attributes: "id", "name"
      files: [] # List of objects with the following attributes: "id", "name", "filename", "MIME_type", "size", "url", "lossy_filename"

    defaultOLDJSONUser:
      id: null
      first_name: null
      last_name: null
      role: null

    defaultOLDJSONSpeaker:
      id: null
      first_name: null
      last_name: null
      dialect: null

    defaultOLDJSONElicitationMethod:
      id: null
      name: null

    defaultOLDJSONSyntacticCategory: ->
      id: null
      name: null

    defaultOLDJSONSource:
      id: null
      type: null
      key: null
      journal: null
      editor: null
      chapter: null
      pages: null
      publisher: null
      booktitle: null
      school: null
      institution: null
      year: null
      author: null
      title: null
      node: null

    # TODO: if OLD AJAX persistence, validate in accordance with oldFormSchema below.
    validate: (attrs, options) ->

    # oldFormSchema reflects how server-side OLD validation occurs.
    # Modify this to provide client-side OLD-compatible validation.
    _oldFormSchema:
      transcription: null # ValidOrthographicTranscription(not_empty=True, max=255)
      phonetic_transcription: null # = ValidBroadPhoneticTranscription(max=255)
      narrow_phonetic_transcription: null # = ValidNarrowPhoneticTranscription(max=255)
      morpheme_break: null # = ValidMorphemeBreakTranscription(max=255)
      grammaticality: null # = ValidGrammaticality()
      morpheme_gloss: null # = UnicodeString(max=255)
      translations: null # = ValidTranslations(not_empty=True)
      comments: null # = UnicodeString()
      speaker_comments: null # = UnicodeString()
      syntax: null # = UnicodeString(max=1023)
      semantics: null # = UnicodeString(max=1023)
      status: null # = OneOf(h.form_statuses)
      elicitation_method: @defaultOLDJSONElicitationMethod # = ValidOLDModelObject(model_name='ElicitationMethod')
      syntactic_category: null # = ValidOLDModelObject(model_name='SyntacticCategory')
      speaker: null # = ValidOLDModelObject(model_name='Speaker')
      elicitor: null # = ValidOLDModelObject(model_name='User')
      verifier: null # = ValidOLDModelObject(model_name='User')
      source: null # = ValidOLDModelObject(model_name='Source')
      tags: null # = ForEach(ValidOLDModelObject(model_name='Tag'))
      files: null # = ForEach(ValidOLDModelObject(model_name='File'))
      date_elicited: null # = DateConverter(month_style='mm/dd/yyyy')

    parse: (response, options) ->
      response

    getOLDURL: -> globals.applicationSettings.get('activeServer').get 'url'

    # Issue a GET request to /forms/new on the active OLD server.
    # This returns a JSON object containing the data necessary to
    # create a new OLD form, an object with keys like `grammaticalities`,
    # `elicitation_methods`, `users`, `speakers`, etc. See:
    # https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/controllers/forms.py#L160
    # https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/controllers/forms.py#L454-L524
    getOLDNewFormData: ->
      Backbone.trigger 'getOLDNewFormDataStart'
      FormModel.cors.request(
        method: 'GET'
        url: "#{@getOLDURL()}/forms/new"
        onload: (responseJSON) =>
          Backbone.trigger 'getOLDNewFormDataEnd'
          Backbone.trigger 'getOLDNewFormDataSuccess', responseJSON
          # TODO: trigger FAIL event if appropriate (how do we know?)
          # Backbone.trigger 'getOLDNewFormDataFail',
          #     "Failed in fetching the data."
        onerror: (responseJSON) =>
          Backbone.trigger 'getOLDNewFormDataEnd'
          Backbone.trigger 'getOLDNewFormDataFail',
            'Error in GET request to OLD server for /forms/new'
          console.log 'Error in GET request to OLD server for /forms/new'
      )

    # Return the datumFields of the currently active corpus, if applicable;
    # otherwise []. Cf. non-DRY `/views/base.coffee:getCorpusDatumFields`.
    getCorpusDatumFields: ->
      try
        globals.applicationSettings
          .get('activeFieldDBCorpusModel').get 'datumFields'
      catch
        []

