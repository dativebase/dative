define [
  './user-old'
  './date-field-display'
  './html-snippet-display-circular'
], (UserView, DateFieldDisplayView, HTMLSnippetFieldDisplayViewCircular) ->

  # User View -- Circular
  # ---------------------
  #
  # I call this subclass "circular" because it uses the
  # HTMLSnippetFieldDisplayView class which imports core Dative objects like
  # views for forms, files and collections. Since the `UserView` class is itself
  # (indirectly) imported by these core view classes, circular import
  # dependencies will ensue and bring annoying bugs with them.

  class UserViewCircular extends UserView

    attribute2displayView:
      datetime_modified: DateFieldDisplayView
      html: HTMLSnippetFieldDisplayViewCircular


