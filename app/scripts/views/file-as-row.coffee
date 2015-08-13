define [
  './resource-as-row'
], (ResourceAsRowView) ->

  # File as Row View
  # ----------------
  #
  # A view for displaying a file model as a row of cells, one cell per attribute.

  class FileAsRowView extends ResourceAsRowView

    resourceName: 'file'

    orderedAttributes: [
      'filename'
      'name'
      'MIME_type'
      'id'
      'size'
      'enterer'
      'tags'
      'forms'
    ]

    # Return a string representation for a given `attribute`/`value` pair of
    # this file.
    scalarTransform: (attribute, value) ->
      if @isHeaderRow
        @scalarTransformHeaderRow attribute, value
      else if value
        if attribute in ['elicitor', 'enterer', 'modifier', 'verifier', 'speaker']
          "#{value.first_name} #{value.last_name}"
        else if attribute is 'size'
          @utils.humanFileSize value, true
        else if attribute is 'forms'
          if value.length
            (f.transcription for f in value).join '; '
          else
            ''
        else if attribute is 'tags'
          if value.length
            (t.name for t in value).join ', '
          else
            ''
        else if @utils.type(value) in ['string', 'number']
          value
        else
          JSON.stringify value
      else
        JSON.stringify value

