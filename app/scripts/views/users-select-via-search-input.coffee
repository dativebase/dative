define [
  './resources-select-via-search-input'
  './user-as-row'
  './../models/user-old'
  './../collections/users'
], (ResourcesSelectViaSearchInputView, UserAsRowView, UserModel,
  UsersCollection) ->

  # Users Select Via Search Input View
  # ----------------------------------
  #
  # Interface for selecting *zero or more* user models via a search interface.
  #
  # *Note:* while this interface behaves just like others that inherit from
  # `ResourcesSelectViaSearchInputView`, it is different because if performs
  # its search over an array of user objects that are already present
  # client-side.

  class UsersSelectViaSearchInputView extends ResourcesSelectViaSearchInputView

    # The string returned by this method will be the text of link that
    # represents each selected file.
    resourceAsString: (resource) ->
      "#{resource.first_name} #{resource.last_name}"

    # Change these attributes in subclasses.
    resourceName: 'user'
    resourceModelClass: UserModel
    resourcesCollectionClass: UsersCollection
    resourceAsRowViewClass: UserAsRowView

    # These are the `[<attribute]`s or `[<attribute>, <subattribute>]`s that we
    # "smartly" search over.
    smartStringSearchableFileAttributes: [
      ['id']
      ['first_name']
      ['last_name']
      ['role']
    ]

    # Here we perform the search entirely client side, using the array of users
    # in `@context.options.users`.
    performSearch: (searchTerm=null) ->
      users = @context.options.users
      if @utils.type(searchTerm) is 'string' # could be an event object ...
        @searchTerm = searchTerm
      else
        @searchTerm = @$('[name=search-term]').val()
      searchTerms = @searchTerm.split /\s+/
      # We still need to get an OLD-style query using the superclass's
      # `getSmartQuery` because the results will need it to highlight how they
      # match the search term.
      @query = @getSmartQuery @searchTerm
      if @isIdSearch searchTerms
        results = (u for u in users when u.id is Number(searchTerms[0]))
      else
        results = (u for u in users when @matchesSearchTerms(u, searchTerms))
      @showSearchResultsTableAnimateCheck()
      @closeResourceAsRowViews()
      @searchResultsCount = @reportMatchesFound results
      if @searchResultsCount > 0
        @$('div.resource-results-via-search-table')
          .html @getSearchResultsRows(items: results)
          .scrollLeft 0
        @$('button.select').first().focus()
      else
        @focusAndSelectSearchTerm()

    reportMatchesFound: (results) ->
      count = results.length
      noun = if count is 1 then 'match' else 'matches'
      @$('span.results-count').text "#{count} #{noun}"
      if count > 0
        @$('span.results-showing-count').text "showing #{count}"
      count

    # Return `true` if `user` matches all of the search terms in `searchTerms`.
    matchesSearchTerms: (user, searchTerms) ->
      matchesResults = []
      for term in searchTerms
        matches = false
        for attr in @smartStringSearchableFileAttributes
          if String(user[attr]).indexOf(term) isnt -1
            matches = true
            break
        matchesResults.push matches
      if false in matchesResults
        false
      else
        true

