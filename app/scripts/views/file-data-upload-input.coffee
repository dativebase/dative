define [
  './input'
  './../templates/file-data-upload-input'
], (InputView, fileDataUploadInputTemplate) ->

  # File Data Upload Input View
  # ---------------------------
  #
  # A view for a data input field for uploading file data, e.g., audio or an
  # image.
  #
  # Note: we use the strategy of hiding the real `<input type='file'>` element
  # and using a jQueryUI-styled button to relay the click. See
  # http://stackoverflow.com/questions/572768/styling-an-input-type-file-button

  class FileDataUploadInputView extends InputView

    template: fileDataUploadInputTemplate

    events:
      'click .file-upload-button': 'clickFileUploadInput'
      'change [name=file-upload-input]': 'handleFileSelect'

    clickFileUploadInput: ->
      @$('[name=file-upload-input]').click()

    file: null

    # remove quotation marks, null bytes, and forward and back slashes; replace
    # spaces with underscores; truncate to 255 characters max.
    getValidFilename: (filename) ->
      filename
        .replace(/['"\0/\\]/g, '')
        .replace(/( )/g, '_')[0...255]

    getFileDataBase64: (event) ->
      @fileDataBase64 = event.target.result.match(/,(.*)$/)[1]
      @model.set
        base64_encoded_file: @fileDataBase64
        filename: @file.name
        MIME_type: @file.type
        size: @file.size

      # description = UnicodeString()
      # utterance_type = OneOf(h.utterance_types)
      # speaker = ValidOLDModelObject(model_name='Speaker')
      # elicitor = ValidOLDModelObject(model_name='User')
      # tags = ForEach(ValidOLDModelObject(model_name='Tag'))
      # forms = ForEach(ValidOLDModelObject(model_name='Form'))
      # date_elicited = DateConverter(month_style='mm/dd/yyyy')

    # TODO: this should be expanded and/or made backend-specific.
    allowedFileTypes: [
      'application/pdf'
      'image/gif'
      'image/jpeg'
      'image/png'
      'audio/mpeg'
      'audio/ogg'
      'audio/x-wav'
      'video/mpeg'
      'video/mp4'
      'video/ogg'
      'video/quicktime'
      'video/x-ms-wmv'
    ]

    handleFileSelect: (event) ->
      file = event.target.files[0]
      if file
        @file = file
        validFilename = @getValidFilename @file.name
        reader = new FileReader()
        # attrs of `file`: `name`, `type`, `size` (and `lastModifiedDate`)
        if file.type not in @allowedFileTypes
          console.log "Sorry, files of type #{file.type} cannot be uploaded."
        else if not validFilename
          console.log "Sorry, the filename #{@file.name} is not valid."
        else if file.size < 20971520
          @file.name = validFilename
          reader.onload = (event) => @getFileDataBase64 event
          reader.readAsDataURL file
        else
          console.log 'Wow! That is a big file'
      else
        console.log 'we should trigger an error here indicating that something
          went wrong during file upload'


    render: ->
      @context.class = 'file-upload-button'
      super
      @tooltipify()
      @buttonify()
      @

    # Make title attrs into jQueryUI tooltips.
    tooltipify: ->
      @$('button.dative-tooltip')
        .tooltip
          position: @tooltipPositionLeft '-200'

    disable: ->
      @disableInputs()

    enable: ->
      @enableInputs()


