define [
  './resource'
  './user-add-widget'
  './person-field-display'
  './date-field-display'
  './object-with-name-field-display'
  './field-display'
  './boolean-icon-display'
  './subcorpus'
  './related-model-representation'
  './html-snippet-display'
], (ResourceView, UserAddWidgetView, PersonFieldDisplayView,
  DateFieldDisplayView, ObjectWithNameFieldDisplayView, FieldDisplayView,
  BooleanIconFieldDisplayView, SubcorpusView, RelatedModelRepresentationView,
  HTMLSnippetFieldDisplayView) ->

  # User View
  # ---------
  #
  # For displaying individual users.
  #
  # NOTE !IMPORTANT: these are OLD user resources and this view should not be
  # confused with the `UserView` for FieldDB-style users, which is defined in
  # views/user.coffee.

  class UserView extends ResourceView

    resourceName: 'user'

    resourceAddWidgetView: UserAddWidgetView

    getHeaderTitle: ->
      if @headerTitle
        @headerTitle
      else
        "User #{@model.get 'id'}"

    # Attributes that are always displayed.
    primaryAttributes: [
      'first_name'
      'last_name'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'role'
      'email'
      'affiliation'
      'markup_language'
      'html'
      'input_orthography'
      'output_orthography'
      'datetime_modified'
      'id'
    ]

    render: ->
      super

    # Map attribute names to display view class names.
    # TODO: create a class to display orthographies.
    attribute2displayView:
      datetime_modified: DateFieldDisplayView
      html: HTMLSnippetFieldDisplayView

