define [
  './resources-select-via-search-field'
  './users-select-via-search-input'
], (ResourcesSelectViaSearchFieldView, UsersSelectViaSearchInputView) ->

  class UsersSelectViaSearchFieldView extends ResourcesSelectViaSearchFieldView

    getInputView: ->
      new UsersSelectViaSearchInputView @context

