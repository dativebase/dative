define [
  './field'
  './file-data-upload-input'
], (FieldView, FileDataUploadInputView) ->

  # File Data Upload Field View
  # ---------------------------
  #
  # A view for a data input field for uploading file data, e.g., audio or an
  # image.

  class FileDataUploadFieldView extends FieldView

    getInputView: ->
      new FileDataUploadInputView @context

    # This field needs to listen for a number of filedata-related errors.
    listenForValidationErrors: ->
      @listenTo @context.model, "validationError:#{@attribute}",
        @validationError
      @listenTo @context.model, "validationError:base64_encoded_file",
        @validationError
      @listenTo @context.model, "validationError:fileBLOB",
        @validationError

    # "My error" may be any of a number of filedata-related errors.
    getMyError: (errorObject) ->
      result = null
      for attribute in [@attribute, 'base64_encoded_file', 'fileBLOB']
        if attribute of errorObject
          result = errorObject[attribute]
      result

