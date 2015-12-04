define [
  './base'
  './../models/form'
  './../templates/csv-import-header'
], (BaseView, FormModel, importHeaderTemplate) ->

  # Import Header View
  # ------------------
  #
  # View for the header row of a CSV file.

  class CSVImportHeaderView extends BaseView

    template: importHeaderTemplate
    className: 'import-preview-table-row import-preview-table-header-row'

    initialize: (options) ->
      @rendered = false
      @columnLabels = options.columnLabels
      @sortedFormAttributes = @getSortedFormAttributes()

      # Holds the widths of our columns.
      @columnWidths = []

    events:
      'selectmenuchange .column-header': 'columnHeaderChanged'

    render: ->
      @$el.append @template(
        columnLabels: @columnLabels
        sortedFormAttributes: @sortedFormAttributes
        snake2regular: @utils.snake2regular
      )
      @bordercolors()
      @buttonify()
      @selectmenuify 'select.column-header'
      @rendered = true
      @

    # Make a <select> matching `selector` into into a jQuery selectmenu.
    selectmenuify: (selector='select')->
      @$(selector)
        .selectmenu
          width: 'auto'
          open: (event, ui) ->
            @selectmenuDefaultZIndex = $('.ui-selectmenu-open').first().zIndex()
            $('.ui-selectmenu-open').zIndex 1120
          close: (event, ui) ->
            $('.ui-selectmenu-open').zIndex @selectmenuDefaultZIndex
        .each (index, element) =>
          @transferClassAndTitle @$(element) # so we can tooltipify the selectmenu

    # Get case-insensitive sorted form attributes as array.
    getSortedFormAttributes: ->
      _.keys(FormModel::defaults())
        .sort (a, b) -> a.toLowerCase().localeCompare(b.toLowerCase())

    bordercolors: ->
      @$('.import-preview-table-header-cell')
        .css("border-color", @constructor.jQueryUIColors().defBo)
      @$el.css("border-color", @constructor.jQueryUIColors().defBo)

    disableAllControls: ->
      @$('button').button 'disable'
      @$('select').selectmenu 'option', 'disabled', true

    enableAllControls: ->
      @$('button').button 'enable'
      @$('select').selectmenu 'option', 'disabled', false

    # Get the widths of all of our header cells that contain values, i.e., the
    # ones with <select>s in them.
    getColumnWidths: ->
      @columnWidths = []
      @$('.import-preview-values-cell').each (i, e) =>
        @columnWidths.push @$(e)[0].getBoundingClientRect().width - 11

    # The user-specified value in a column header select box has changed: based
    # on this, we activate/deactivate the column and alter its width.
    columnHeaderChanged: ->
      @getColumnLabels()
      @setColumnActivities()
      @getColumnWidths()
      @trigger 'columnWidthsChanged', @columnWidths
      @trigger 'columnLabelsChanged', @columnLabels

    # Return an object that maps column indices to the user-selected form field
    # labels, e.g., {n: 'transcription'} indicates that the nth row contains
    # transcription values.
    getColumnLabels: ->
      @columnLabels = []
      @$('select.column-header').each (i, e) => @columnLabels.push @$(e).val()

    validate: ->
      @getColumnLabels()
      warnings = []
      for label, index in @columnLabels
        if label not in FormModel::editableAttributesOLD
          if label
            labelHuman = @utils.snake2regular label
            warnings.push "Values in column #{index + 1}
              “#{labelHuman}” will not be imported because #{labelHuman} is
              a read-only and/or system-specified field."
          else
            warnings.push "Values in column #{index + 1} will not be imported"
      [warnings, []]

    # Enable/disable the column based on its user-specified label. If the label
    # corresponds to a non-editable form attribute, e.g., `modifier` or `id`,
    # then we change the display the column to indicate that it is "disabled",
    # i.e., that it won't be included in the import.
    setColumnActivities: ->
      @$('.import-preview-values-cell').each (i, e) =>
        $e = @$ e
        label = @columnLabels[i]
        if label
          if label in FormModel::editableAttributesOLD
            $e.find('i.column-alert').hide()
          else
            $e.find('i.column-alert').show().tooltip
              content: "Values in this column will not be imported because
                users cannot specify “#{@utils.snake2regular label}”
                values; they can only be specified by the system."
        else
          $e.find('i.column-alert').show().tooltip
            content: 'Values in this column will not be imported; please choose
              a form field label for this column.'

