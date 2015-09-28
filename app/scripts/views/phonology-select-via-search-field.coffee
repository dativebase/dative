define [
  './resource-select-via-search-field'
  './phonology-select-via-search-input'
], (ResourceSelectViaSearchFieldView, PhonologySelectViaSearchInputView) ->

  class PhonologySelectViaSearchFieldView extends ResourceSelectViaSearchFieldView

    getInputView: ->
      new PhonologySelectViaSearchInputView @context


