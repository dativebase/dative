define [
    'underscore'
    'backbone'
    './database'
    './base'
    #'backboneindexeddb'
  ], (_, Backbone, database, BaseModel) ->

    # Form Model
    # ----------
    #
    # First stab at a form model.
    # This is a model that attempts to be compatible with an OLD 1.0 RESTful
    # web service
    #
    # Models are for conversions, validations, computed properties, and access
    # control.
    #
    # Future development:
    #
    # - relationality via backbone-relational
    # - LingSync compatibility
    # - client-side storage via indexeddb

    class FormModel extends BaseModel

      #idbSync: Backbone.sync
      #sync: Backbone.ajaxSync

      initialize: ->

      url: 'fakeurl' # Backbone throws 'A "url" property or function must be specified' if this is not present.
      #url: 'http://www.onlinelinguisticdatabase.org/'
      #url: 'http://www.fake-old-url.org/'

      # Backbone-IndexedDB requires `database` and `storeName`
      database: database
      storeName: 'forms'

      defaults: =>
        @oldFormSchema()

      # OLD 1.0a1 Form schema
      # The comments after each line are the Python/SQLAlchemy column constraints and definitions
      #__tablename__ = "form"
      oldFormSchema: ->
        id: null # integer, primary key
        UUID: null # an implicit primary key (used for versioning)
        transcription: "" # Column(Unicode(255), nullable=False)
        phonetic_transcription: "" # Column(Unicode(255))
        narrow_phonetic_transcription: "" # Column(Unicode(255))
        morpheme_break: "" # Column(Unicode(255))
        morpheme_gloss: "" # Column(Unicode(255))
        comments: "" # Column(UnicodeText)
        speaker_comments: "" # Column(UnicodeText)
        grammaticality: "" # Column(Unicode(255))
        date_elicited: null # Column(Date)
        datetime_entered: null # Column(DateTime)
        datetime_modified: null # Column(DateTime, default=now)
        syntactic_category_string: "" # Column(Unicode(255))
        morpheme_break_ids: [] # Column(UnicodeText)
        morpheme_gloss_ids: [] # Column(UnicodeText)
        break_gloss_category: "" # Column(Unicode(1023))
        syntax: "" # Column(Unicode(1023))
        semantics: "" # Column(Unicode(1023))
        status: "" # Column(Unicode(40), default=u'tested')  # u'tested' vs. u'requires testing'

        # Many-to-one relations
        elicitor: @defaultOLDJSONUser # relation('User', primaryjoin='Form.elicitor_id==User.id') elicitor_id: null # Column(Integer, ForeignKey('user.id', ondelete='SET NULL'))
        enterer: @defaultOLDJSONUser # relation('User', primaryjoin='Form.enterer_id==User.id') enterer_id: null # Column(Integer, ForeignKey('user.id', ondelete='SET NULL'))
        modifier: @defaultOLDJSONUser # relation('User', primaryjoin='Form.modifier_id==User.id') modifier_id: null # Column(Integer, ForeignKey('user.id', ondelete='SET NULL'))
        verifier: @defaultOLDJSONUser # relation('User', primaryjoin='Form.verifier_id==User.id') verifier_id: null # Column(Integer, ForeignKey('user.id', ondelete='SET NULL'))
        speaker: @defaultOLDJSONSpeaker # relation('Speaker') speaker_id: null # Column(Integer, ForeignKey('speaker.id', ondelete='SET NULL'))
        elicitation_method: @defaultOLDJSONElicitationMethod# relation('ElicitationMethod') elicitationmethod_id: null # Column(Integer, ForeignKey('elicitationmethod.id', ondelete='SET NULL'))
        syntactic_category: @defaultOLDJSONSyntacticCategory() # relation('SyntacticCategory', backref='forms') syntacticcategory_id: null # Column(Integer, ForeignKey('syntacticcategory.id', ondelete='SET NULL'))
        source: @defaultOLDJSONSource# relation('Source') source_id: null # Column(Integer, ForeignKey('source.id', ondelete='SET NULL'))

        # One-to-many relations
        translations: [] # relation('Translation', backref='form', cascade='all, delete, delete-orphan')

        # Many-to-many relations
        files: [] # relation('File', secondary=FormFile.__table__, backref='forms')
        collections: [] # relation('Collection', secondary=CollectionForm.__table__, backref='forms')
        tags: [] # relation('Tag', secondary=FormTag.__table__, backref='forms')

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

