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

    listenToEvents: ->
      super
      @listenTo @model, 'uploadProgress', @refreshProgressBar

    refreshProgressBar: (percentComplete) ->
      $fileUploadContainer = @$ '.file-upload-container'
      $fileUploadProgressBar = @$('.file-upload-progress-bar').first()
      if $fileUploadContainer.is ':hidden'
        @$('.file-upload-container').show()
      if percentComplete >= 100
        text = 'Upload complete. Waiting for server to respond.'
        if $fileUploadProgressBar.is ':visible'
          $fileUploadProgressBar.hide()
      else
        text = 'Uploading file data ...'
        if $fileUploadProgressBar.is ':hidden'
          $fileUploadProgressBar.show()
        $fileUploadProgressBar.show()
          .progressbar 'value', percentComplete
      @$('.file-upload-status').text text

    events:
      'click .file-upload-button': 'clickFileUploadInput'
      'change [name=file-upload-input]': 'handleFileSelect'

    clickFileUploadInput: ->
      @$('[name=file-upload-input]').click()

    file: null

    # Make the filename into a valid one (given the OLD's requirements); that
    # is, remove quotation marks, null bytes, and forward and back slashes;
    # replace spaces with underscores; truncate to 255 characters max.
    getValidFilename: (filename) ->
      filename
        .replace(/['"\0/\\]/g, '')
        .replace(/( )/g, '_')[0...255]

    # Handle the successful loading of a selected (small) file where the data
    # are base64-encoded. Note that changing the value of `base64_encoded_file`
    # on the model will cause the file data display view to refresh the display
    # of the file.
    fileDataLoadBase64Success: (event) ->
      @fileDataBase64 = event.target.result.match(/,(.*)$/)[1]
      filename = @validFilename or @fileBLOB.name
      @model.set
        filedata: null
        base64_encoded_file: @fileDataBase64
        blobURL: ''
        filename: filename
        MIME_type: @fileBLOB.type
        size: @fileBLOB.size

    # Handle the successful loading of a selected (large) file. Note that
    # creating a URL from the `BLOB` instance and setting the model's `blobURL`
    # to that value will cause the file data display view to refresh the
    # display of the file.
    fileDataLoadMultipartSuccess: (event) ->
      fileURL = URL.createObjectURL @fileBLOB
      filename = @validFilename or @fileBLOB.name
      @model.set
        filedata: @fileBLOB
        base64_encoded_file: ''
        blobURL: fileURL
        filename: filename
        MIME_type: @fileBLOB.type
        size: @fileBLOB.size

    # Reset the filedata-associated attributes to their default values. This is
    # useful for when something goes wrong with file selection or file loading.
    resetFileDataMetadata: ->
      @model.set
        filedata: null
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
      Backbone.trigger 'fileDataLoadError', @fileBLOB

    spinnerOptions: ->
      options = super
      options.top = '50%'
      options.left = '120%'
      options.color = @constructor.jQueryUIColors().defCo
      options

    spin: ->
      @$('button.file-upload-button').spin @spinnerOptions()

    stopSpin: ->
      @$('button.file-upload-button').spin false

    # Handle the user selecting a file from their file system. In the
    # successful cases, this will result in the file being displayed in the GUI
    # and the filedata-related attributes being valuated.
    # Note: the attributes of the `fileBLOB` object are `name`, `type`, `size`,
    # `lastModified` (timestamp), and `lastModifiedDate` (`Date` instance).
    handleFileSelect: (event) ->
      fileBLOB = event.target.files[0]
      if fileBLOB
        @fileBLOB = fileBLOB
        @validFilename = @getValidFilename @fileBLOB.name
        if fileBLOB.type not in @allowedFileTypes
          @forbiddenFile @fileBLOB
        else if not @validFilename.split('.').shift()
          @invalidFilename @fileBLOB
        else
          reader = new FileReader()
          reader.onloadstart = (event) => @fileDataLoadStart event
          reader.onloadend = (event) => @fileDataLoadEnd event
          reader.onerror = (event) => @fileDataLoadError event
          # Files with smaller data have their data sent as base64-encoded data
          # in a JSON object.
          if @fileBLOB.size < 20971520
            reader.onload = (event) => @fileDataLoadBase64Success event
            reader.readAsDataURL @fileBLOB
          # Files with larger data have their data sent as multipart/form-data.
          else
            reader.onload = (event) => @fileDataLoadMultipartSuccess event
            reader.readAsBinaryString @fileBLOB
      else
        Backbone.trigger 'fileSelectError'
        @resetFileDataMetadata()

    # Tell the user that the file they tried to select cannot be uploaded/saved
    # in Dative.
    forbiddenFile: (fileBLOB) ->
      if fileBLOB.type
        errorMessage = "Sorry, files of type #{fileBLOB.type} cannot be
          uploaded."
      else
        errorMessage = "The file you have selected has no recognizable
          type."
      Backbone.trigger 'fileSelectForbiddenType', errorMessage
      @resetFileDataMetadata()

    # Tell the user that the file they tried to select has an invalid filename.
    invalidFilename: (fileBLOB) ->
      errorMessage = "Sorry, the filename #{@fileBLOB.name} is not
        valid."
      Backbone.trigger 'fileSelectInvalidName', errorMessage
      @resetFileDataMetadata()

    render: ->
      @context.class = 'file-upload-button'
      super
      @tooltipify()
      @buttonify()
      @progressBarify()
      @

    progressBarify: ->
      @$('.file-upload-container').hide()
      @$('.file-upload-progress-bar').first().progressbar()

    # Make title attrs into jQueryUI tooltips.
    tooltipify: ->
      @$('button.dative-tooltip')
        .tooltip
          position: @tooltipPositionLeft '-200'

    disable: ->
      @disableInputs()

    enable: ->
      @enableInputs()

