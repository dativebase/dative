define [
  './related-resource-field-display'
  './source'
  './../models/source'
  './../collections/sources'
], (RelatedResourceFieldDisplayView, SourceView, SourceModel,
  SourcesCollection) ->

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
    resourcesCollectionClass: SourcesCollection
    resourceViewClass: SourceView

    resourceAsString: (resource) ->
      try
        r = (new @resourceModelClass(resource)).getAuthorEditorYearDefaults()

        # It is too difficult to correctly highlight the exact matches in a
        # source-as-string representation so we simply highlight the whole
        # thing if the source was matched in the search.
        if @context.searchPatternsObject
          if @attributeName of @context.searchPatternsObject
            sourceIsMatched = false
            for subattribute, re of @context.searchPatternsObject[@attributeName]
              if re.test resource[subattribute]
                sourceIsMatched = true
                break
            if sourceIsMatched
              r = "<span class='dative-state-highlight'>#{r}</span>"
        r
      catch
        ''

