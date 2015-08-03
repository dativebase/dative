define [
  './related-resource-field-display'
  './speaker'
  './../models/speaker'
], (RelatedResourceFieldDisplayView, SpeakerView, SpeakerModel) ->

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
    resourceViewClass: SpeakerView

    resourceAsString: (resource) ->
      try
        firstName = resource.first_name or ''
        lastName = resource.last_name or ''
        "#{firstName} #{lastName}".trim()
      catch
        ''


