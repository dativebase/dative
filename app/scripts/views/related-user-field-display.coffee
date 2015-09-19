define [
  './related-resource-field-display'
  './user-old'
  './../models/user-old'
  './../collections/users'
], (RelatedResourceFieldDisplayView, UserView, UserModel, UsersCollection) ->

  # Related User Field Display View
  # -------------------------------
  #
  # For displaying a user as a field/attribute of another resource, such that
  # the user is displayed as a link that, when clicked, causes the resource to
  # be displayed in a dialog box.

  class RelatedUserFieldDisplayView extends RelatedResourceFieldDisplayView

    resourceName: 'user'
    resourceModelClass: UserModel
    resourcesCollectionClass: UsersCollection
    resourceViewClass: UserView

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

