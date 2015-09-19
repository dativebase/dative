define [
  './resource'
  './page-add-widget'
  './date-field-display'
  './html-snippet-display'
], (ResourceView, PageAddWidgetView, DateFieldDisplayView,
  HTMLSnippetFieldDisplayView) ->

  # Page View
  # ---------
  #
  # For displaying individual pages.

  class PageView extends ResourceView

    resourceName: 'page'

    resourceAddWidgetView: PageAddWidgetView

    # Attributes that are always displayed.
    primaryAttributes: ['name']

    # Attributes that may be hidden.
    secondaryAttributes: [
      'heading'
      'markup_language'
      'html'
      'datetime_modified'
      'id'
    ]

    # Map attribute names to display view class names.
    attribute2displayView:
      datetime_modified: DateFieldDisplayView
      html: HTMLSnippetFieldDisplayView

