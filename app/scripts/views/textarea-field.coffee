define [
  './field'
], (FieldView) ->

  # Textarea Field View
  # -------------------
  #
  # A view for a data input field that is a textarea (with a label and
  # validation machinery, as inherited from FieldView.)

  class TextareaFieldView extends FieldView

