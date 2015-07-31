define [
  './resource'
  './speaker-add-widget'
  './date-field-display'
  './html-snippet-display'
], (ResourceView, SpeakerAddWidgetView, DateFieldDisplayView,
  HTMLSnippetFieldDisplayView) ->

  # Speaker View
  # ------------
  #
  # For displaying individual speakers.

  class SpeakerView extends ResourceView

    resourceName: 'speaker'

    resourceAddWidgetView: SpeakerAddWidgetView

    getHeaderTitle: ->
      try
        "#{@model.get 'first_name'} #{@model.get 'last_name'}"
      catch
        super

    # Attributes that are always displayed.
    primaryAttributes: [
      'dialect'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'markup_language'
      'html'
      'datetime_modified'
      'id'
    ]

    # Map attribute names to display view class names.
    attribute2displayView:
      datetime_modified: DateFieldDisplayView
      html: HTMLSnippetFieldDisplayView

