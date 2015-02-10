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

  class FormModel extends BaseModel

    url: 'fakeurl' # Backbone throws 'A "url" property or function must be specified' if this is not present.

    ############################################################################
    # Dative Schema
    ############################################################################

    # Note: the comments in this method definition reflect the OLD's relational schema
    # and will be removed later.
    defaults: ->
      id: null # integer in OLD, UUID in FieldDB
      UUID: null # OLD only
      transcription: "" # Column(Unicode(255), nullable=False)
      phoneticTranscription: "" # Column(Unicode(255))
      narrowPhoneticTranscription: "" # Column(Unicode(255))
      morphemeBreak: "" # Column(Unicode(255))
      morphemeGloss: "" # Column(Unicode(255))
      comments: "" # Column(UnicodeText)
      speakerComments: "" # OLD only; Column(UnicodeText)
      grammaticality: "" # FieldDB `judgement`; OLD Column(Unicode(255))
      dateElicited: null # Column(Date)
      datetimeEntered: null # FieldDB `dateEntered`; OLD Column(DateTime)
      datetimeModified: null # FieldDB `dateModified`; OLD  Column(DateTime, default=now)
      syntacticCategories: "" # FieldDB `syntacticCategory`, OLD `syntacticCategoryString` Column(Unicode(255))
      morphemeBreakIds: [] # OLD only; Column(UnicodeText)
      morphemeGlossIds: [] # OLD only; Column(UnicodeText)
      breakGlossCategory: "" # OLD only; Column(Unicode(1023))
      syntacticTreePTB: "" # OLD `syntax`: Column(Unicode(1023))
      semantics: "" # OLD only: Column(Unicode(1023))
      status: "" # `status` in the OLD, `validationStatus` in FieldDB: see the comments in `fieldDB2dative` below. Column(Unicode(40), default=u'tested')  # u'tested' vs. u'requires testing'

      # FieldDB-only attributes
      syntacticTreeLaTeX: ""
      consultants: "" # just a string. In `sessionFields`. Values I've seen are: "AB"; I expect "AB CD FG" would be an anticipated value too.
      fieldDBTags: "" # just a string. This is FieldDB `tags`.
      fieldDBDatumTags: [] # Is this an array? This is meant to hold FieldDB `datumTags`. TODO: figure this out.
      modifiers: [] # This is `datumFields.modifiedByUser`: an array of users who have modified the form; TODO: figure out if these objects are ordered and which attributes they have.
      fieldDBComments:[] # array of comment objects: {text: '...', username: '...', timestamp: '...'}

      # Template TODOs:
      # - fieldDBDatumTags: @cesine: I don't know what to do with this attribute... Is it only used in the Prototype?
      # - modifiers
      # - fieldDBComments
      #   - QUESTION: why do fieldDBComments have timestampModified values when
      #     they can't be modified? At least, they can't be modified in
      #     Spreadsheet.

      # Many-to-one relations
      elicitor: @defaultUser() # relation('User', primaryjoin='Form.elicitor_id==User.id') elicitor_id: null # Column(Integer, ForeignKey('user.id', ondelete='SET NULL'))
      enterer: @defaultUser() # @defaultUser() # relation('User', primaryjoin='Form.enterer_id==User.id') enterer_id: null # Column(Integer, ForeignKey('user.id', ondelete='SET NULL'))
      modifier: @defaultUser() # relation('User', primaryjoin='Form.modifier_id==User.id') modifier_id: null # Column(Integer, ForeignKey('user.id', ondelete='SET NULL'))
      verifier: @defaultUser() # relation('User', primaryjoin='Form.verifier_id==User.id') verifier_id: null # Column(Integer, ForeignKey('user.id', ondelete='SET NULL'))
      speaker: @defaultSpeaker # relation('Speaker') speaker_id: null # Column(Integer, ForeignKey('speaker.id', ondelete='SET NULL'))
      elicitationMethod: @defaultElicitationMethod # relation('ElicitationMethod') elicitationmethod_id: null # Column(Integer, ForeignKey('elicitationmethod.id', ondelete='SET NULL'))
      syntacticCategory: @defaultSyntacticCategory() # relation('SyntacticCategory', backref='forms') syntacticcategory_id: null # Column(Integer, ForeignKey('syntacticcategory.id', ondelete='SET NULL'))
      source: @defaultSource# relation('Source') source_id: null # Column(Integer, ForeignKey('source.id', ondelete='SET NULL'))

      # One-to-many relations
      translations: [] # relation('Translation', backref='form', cascade='all, delete, delete-orphan')

      # Many-to-many relations
      files: [] # relation('File', secondary=FormFile.__table__, backref='forms')
      collections: [] # relation('Collection', secondary=CollectionForm.__table__, backref='forms')
      tags: [] # relation('Tag', secondary=FormTag.__table__, backref='forms')

    defaultUser: ->
      id: null
      firstName: null
      lastName: null
      role: null
      username: null

    defaultSpeaker: ->
      id: null
      firstName: null
      lastName: null
      dialect: null

    defaultElicitationMethod: ->
      id: null
      name: null

    defaultSyntacticCategory: ->
      id: null
      name: null

    defaultSource: ->
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
    ############################################################################

    # FieldDb to Dative: input: a FieldDB datum object, output: a Dative form model
    # --------------------------------------------------------------------------
    #
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

    fieldDB2dative: (fieldDBDatum) ->
      # console.log 'in fieldDB2dative'
      # console.log JSON.stringify(fieldDBDatum, undefined, 2)
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
      enterer = @defaultUser()
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
    ############################################################################

    # Convert an OLD form object to a Dative form object.
    # An OLD form is received as a JSON object. See
    # http://online-linguistic-database.readthedocs.org/en/latest/datastructure.html#form
    # for an exact specification of its attributes and their validation
    # requirements.
    old2dative: (oldForm) ->
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
          # console.log JSON.stringify(responseJSON, undefined, 2)
          Backbone.trigger 'getOLDNewFormDataSuccess', responseJSON
          # TODO: trigger FAIL event if appropriate (how do we know?)
          # Backbone.trigger 'getOLDNewFormDataFail',
          #     "Failed in fetching the data."
          # console.log "GET request to OLD server for /forms/new failed"
        onerror: (responseJSON) =>
          Backbone.trigger 'getOLDNewFormDataEnd'
          Backbone.trigger 'getOLDNewFormDataFail',
            'Error in GET request to OLD server for /forms/new'
          console.log 'Error in GET request to OLD server for /forms/new'
      )

