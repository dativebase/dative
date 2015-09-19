define [
  './related-resource-field-display'
  './speaker'
  './../models/speaker'
  './../collections/speakers'
], (RelatedResourceFieldDisplayView, SpeakerView, SpeakerModel,
  SpeakersCollection) ->

  # Related Speaker Field Display View
  # ----------------------------------
  #
  # For displaying a speaker as a field/attribute of another resource, such that
  # the speaker is displayed as a link that, when clicked, causes the resource to
  # be displayed in a dialog box.

  class SpeakerFieldDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'speaker'
    attributeName: 'speaker'
    resourceModelClass: SpeakerModel
    resourcesCollectionClass: SpeakersCollection
    resourceViewClass: SpeakerView

    resourceAsString: (resource) ->
      try
        if resource.first_name
          if @context.searchPatternsObject
            try
              regex = @context.searchPatternsObject[@attributeName].first_name
            catch
              regex = null
            if regex
              firstName = @utils.highlightSearchMatch regex, resource.first_name
            else
              firstName = resource.first_name
          else
            firstName = resource.first_name
        else
          firstName = ''
        if resource.last_name
          if @context.searchPatternsObject
            try
              regex = @context.searchPatternsObject[@attributeName].last_name
            catch
              regex = null
            if regex
              lastName = @utils.highlightSearchMatch regex, resource.last_name
            else
              lastName = resource.last_name
          else
            lastName = resource.last_name
        else
          lastName = ''
        "#{firstName} #{lastName}".trim()
      catch
        ''

    getContext: ->
      context = super
      context.valueFormatter = (v) -> v
      context

    __resourceAsString__: (resource) ->
      try
        firstName = resource.first_name or ''
        lastName = resource.last_name or ''
        "#{firstName} #{lastName}".trim()
      catch
        ''

