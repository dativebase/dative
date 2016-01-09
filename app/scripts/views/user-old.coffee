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
        if @model.get('id')
          "#{@model.get 'username'} (user #{@model.get 'id'})"
        else
          'New User'

    # Attributes that are always displayed.
    primaryAttributes: [
      'first_name'
      'last_name'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: [
      'username'
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

    initialize: (options) ->
      if @imAdmin()
        @excludedActions = [
          'history'
          'controls'
          'data'
          'settings'
        ]
      else if @imAdminOrImResource()
        @excludedActions = [
          'history'
          'controls'
          'data'
          'settings'
          'delete'
          'duplicate'
        ]
      else
        @excludedActions = [
          'history'
          'controls'
          'data'
          'settings'
          'update'
          'delete'
          'duplicate'
        ]
      super options

    # Map attribute names to display view class names.
    # TODO: create a class to display orthographies.
    attribute2displayView:
      datetime_modified: DateFieldDisplayView
      html: HTMLSnippetFieldDisplayView

