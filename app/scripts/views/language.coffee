define [
  './resource'
  './date-field-display'
  './field-display'
  './enterer-field-display'
  './modifier-field-display'
], (ResourceView, DateFieldDisplayView, EntererFieldDisplayView,
  ModifierFieldDisplayView) ->

  # Language View
  # --------
  #
  # For displaying individual languages. Note that there is no
  # `LanguageAddWidgetView` since languages are read-only.

  class LanguageView extends ResourceView

    # The default behaviour for `ResourceView` is to return `'add'` of the
    # model has no `id` attribute. However, since ISO 639-3 language resources
    # are immutable, we don't neither "update" nor "add" make sense here. We
    # return `'update'` because this will prevent the "x" button ("hide this
    # new language widget") button from being displayed.
    getUpdateViewType: -> 'update'

    resourceName: 'language'

    resourceAddWidgetView: null

    excludedActions: [
      'history'
      'controls'
      'data'
      'update' # you can't update read-only language resources
    ]

    getHeaderTitle: -> @model.get 'Id'

    # Attributes that are always displayed.
    primaryAttributes: [
      'Id'
      'Ref_Name'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'Part2B'
      'Part2T'
      'Part1'
      'Scope'
      'Type'
      'Comment'
      'datetime_modified'
    ]

    # Map attribute names to display view class names.
    # TODO: an uneditable resource shouldn't have a datetime modified
    # attribute, should it?
    attribute2displayView:
      datetime_modified: DateFieldDisplayView

