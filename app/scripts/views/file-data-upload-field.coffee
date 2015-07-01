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

