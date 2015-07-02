define [
  './input'
  './../utils/globals'
  './../templates/file-data-upload-input'
], (InputView, globals, fileDataUploadInputTemplate) ->

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

    initialize: (@context) ->
      @allowedFileTypes = globals.applicationSettings.get 'allowedFileTypes'

    template: fileDataUploadInputTemplate

    validFilename: ''

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

    fileDataLoadSuccess: (event) ->
      @fileDataBase64 = event.target.result.match(/,(.*)$/)[1]
      filename = @validFilename or @fileMetadata.name
      @model.set
        base64_encoded_file: @fileDataBase64
        blobURL: ''
        filename: filename
        MIME_type: @fileMetadata.type
        size: @fileMetadata.size

    refreshFileDataView: (fileURL) ->
      filename = @validFilename or @fileMetadata.name
      @model.set
        base64_encoded_file: ''
        blobURL: fileURL
        filename: filename
        MIME_type: @fileMetadata.type
        size: @fileMetadata.size

    resetFileDataMetadata: ->
      @model.set
        base64_encoded_file: ''
        blobURL: ''
        filename: ''
        MIME_type: ''
        size: null

    fileDataLoadStart: (event) ->
      @spin()

    fileDataLoadEnd: (event) ->
      @stopSpin()

    fileDataLoadError: (event) ->
      Backbone.trigger 'fileDataLoadError', @fileMetadata

    spinnerOptions: ->
      options = super
      options.top = '50%'
      options.left = '100%'
      options.color = @constructor.jQueryUIColors().defCo
      options

    spin: ->
      @$('button.file-upload-button').spin @spinnerOptions()

    stopSpin: ->
      @$('button.file-upload-button').spin false

      # description = UnicodeString()
      # utterance_type = OneOf(h.utterance_types)
      # speaker = ValidOLDModelObject(model_name='Speaker')
      # elicitor = ValidOLDModelObject(model_name='User')
      # tags = ForEach(ValidOLDModelObject(model_name='Tag'))
      # forms = ForEach(ValidOLDModelObject(model_name='Form'))
      # date_elicited = DateConverter(month_style='mm/dd/yyyy')

    # This is called when the user chooses a file from their local file system.
    # The attributes of the `fileMetadata` object are `name`, `type`, `size`,
    # `lastModified` (timestamp), and `lastModifiedDate` (`Date` instance).
    handleFileSelect: (event) ->
      fileMetadata = event.target.files[0]
      if fileMetadata
        @fileMetadata = fileMetadata
        @validFilename = @getValidFilename @fileMetadata.name
        if fileMetadata.type not in @allowedFileTypes
          @forbiddenFile @fileMetadata
        else if not @validFilename.split('.').shift()
          @invalidFilename @fileMetadata
        else
          if @fileMetadata.size < 20971520
            reader = new FileReader()
            reader.onloadstart = (event) => @fileDataLoadStart event
            reader.onloadend = (event) => @fileDataLoadEnd event
            reader.onerror = (event) => @fileDataLoadError event
            reader.onload = (event) => @fileDataLoadSuccess event
            reader.readAsDataURL @fileMetadata
          else
            fileURL = URL.createObjectURL @fileMetadata
            @refreshFileDataView fileURL
      else
        Backbone.trigger 'fileSelectError'
        @resetFileDataMetadata()

    forbiddenFile: (fileMetadata) ->
      if fileMetadata.type
        errorMessage = "Sorry, files of type #{fileMetadata.type} cannot be
          uploaded."
      else
        errorMessage = "The file you have selected has no recognizable
          type."
      Backbone.trigger 'fileSelectForbiddenType', errorMessage
      @resetFileDataMetadata()

    invalidFilename: (fileMetadata) ->
      errorMessage = "Sorry, the filename #{@fileMetadata.name} is not
        valid."
      Backbone.trigger 'fileSelectInvalidName', errorMessage
      @resetFileDataMetadata()

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


