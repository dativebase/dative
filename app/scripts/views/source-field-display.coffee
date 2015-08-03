define [
  './related-resource-field-display'
  './source'
  './../models/source'
  './../utils/bibtex'
], (RelatedResourceFieldDisplayView, SourceView, SourceModel, BibTeXUtils) ->

  # Related Source Field Display View
  # ----------------------------------
  #
  # For displaying a source as a field/attribute of another resource, such that
  # the source is displayed as a link that, when clicked, causes the resource to
  # be displayed in a dialog box.

  class SourceFieldDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'source'
    attributeName: 'source'
    resourceModelClass: SourceModel
    resourceViewClass: SourceView

    resourceAsString: (resource) ->
      try
        "#{BibTeXUtils.getAuthor resource} (#{BibTeXUtils.getYear resource})"
      catch
        ''

