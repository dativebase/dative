define ['./resource'], (ResourceModel) ->

  # File Model
  # ---------------
  #
  # A Backbone model for Dative files. Note: currently assumes OLD files as the
  # server-side counterpart.
  #
  # NOTE/WARNING: OLD files are more complicated than typical resources becuase
  # there are various types of file resource with different attributes. The
  # differences are based on whether the file data are stored elsewhere and on
  # whether the file data are sent to the OLD as a Base64-encoded string or as
  # binary data using the multipart/form-data content type. See
  # https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/controllers/files.py#L128-L193.

  class FileModel extends ResourceModel

    resourceName: 'file'

    editableAttributes: []

    manyToOneAttributes: []

    manyToManyAttributes: []

    getValidator: (attribute) ->
      null

    ############################################################################
    # File Schema
    ############################################################################

    # See:
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/lib/schemata.py#L1091-L1111
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/corpus.py#L82-L104
    # - https://github.com/jrwdunham/old/blob/master/onlinelinguisticdatabase/model/model.py

    defaults: ->

      # These attributes are relevant to all file types (regardless of where
      # the file data are stored or how they are uploaded). They are also
      # relevant on update requests.
      description: ''         # A description of the file.
      utterance_type: ''      # If the file represents a recording of an
                              # utterance, then a value here may be
                              # appropriate; possible values accepted by the
                              # OLD currently are 'None', 'Object Language
                              # Utterance', 'Metalanguage Utterance', and
                              # 'Mixed Utterance'.
      speaker: null           # A reference to the OLD speaker who was the
                              # speaker of this file, if appropriate.
      elicitor: null          # A reference to the OLD user who elicited this
                              # file, if appropriate.
      tags: []                # An array of OLD tags assigned to the file.
      forms: []               # An array of forms associated to this file.
      date_elicited: ''       # When this file was elicited, if appropriate.

      # `base64_encoded_file`: When creating a file, this attribute may contain
      # a base-64 encoded string representation of the file data, so long as
      # the file size does not exceed 20MB.

      filename: ''            # the filename, cannot be empty, max 255 chars.
                              # Note: the OLD will remove quotation marks and
                              # replace spaces with underscores. Note also that
                              # the OLD will not allow the file to be created
                              # if the MIMEtype guessed on the basis of the
                              # filename is different from that guessed on the
                              # basis of the file data.
      name: ''                # the name of the file, max 255 chars; QUESTION:
                              # how is this different from `filename` above?
      MIME_type: ''           # a string representing the MIME type.

      # Externally hosted file attributes. These attributes relevant only to
      # files whose file data are stored elsewhere, i.e., not on an OLD web
      # service.
      url: ''                 # a valid URL where that resolves to the file
                              # data.
      password: ''            # If needed, this field should contain the value
                              # of a password needed to access the file on the
                              # server where it is stored.

      # Subinterval-referencing file attributes. These attributes are relevant
      # only to file objects that reference an existing file object for their
      # file data and specify, in addition, start and end points within the
      # parent file to represent their file content/data.
      # NOTE: a valuated `name` attribute is also required when creating a file
      # in this way.
      parent_file: null       # a reference to an existing OLD audio/video
                              # file; note: the creator must have permission to
                              # access the parent file, it must exist, it must
                              # be audio/video, it cannot be empty, and the
                              # parent file cannot itself be a
                              # subinterval-referencing file.
      start: null             # start time of the subinterval; a value must be
                              # specified, it must be a number, and it must be
                              # less than `end`.
      end: null               # end time of the subinterval; a value must be
                              # specified, it must be a number, and it must be
                              # greater than `start`.


      # Attributes that the OLD sends to us, but which the OLD will ignore if
      # we try to send them back.
      id: null                # An integer relational id
      UUID: ''                # A string UUID
      enterer: null           # an object (attributes: `id`, `first_name`,
                              # `last_name`, `role`)
      modifier: null          # an object (attributes: `id`, `first_name`,
                              # `last_name`, `role`)
      datetime_entered: ""    # <string>  (datetime file was created/entered;
                              # generated on the server as a UTC datetime;
                              # communicated in JSON as a UTC ISO 8601 datetime,
                              # e.g., '2015-02-11T10:50:57.821192'.)
      datetime_modified: ""   # <string>  (datetime file was last modified;
                              # format and construction same as
                              # `datetime_entered`.)
      size: null              # calculated server-side
      lossy_filename: ''      # created server-side; name of the lossy copy of
                              # the file, if applicable. E.g., if you upload a
                              # 100MB .wav file named "elicitation.wav", then the
                              # lossy filename may be a 25MB "elicitation.ogg".

