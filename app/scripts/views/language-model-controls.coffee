define [
  './controls'
  './generate-control'
  './get-probabilities-control'
], (ControlsView, GenerateControlView, GetProbabilitiesControlView) ->

  # Language Model Controls View
  # ----------------------------
  #
  # View for a widget containing inputs and controls for manipulating the extra
  # actions of a (morphem) language model (LM) resource. These actions are
  #
  # 1. generating the files that constitute the morpheme language model,
  #    crucially the file that holds the pickled LM trie.
  #    request: PUT /morpheme_language_model/id/generate
  #    terminates: when polling the index action show a changed UUID.
  #
  # 2. getting the probabilities of a sequence of morphemes passed in the JSON
  #    PUT params. 
  #    params: list of morpheme sequences: space-delimited morphemes in
  #    form|gloss|category, format where "|" is actually ``h.rare_delimiter``.
  #    returns: a dictionary with morpheme sequences as keys and log
  #    probabilities as values.
  #
  # 3. compute perplexity
  #
  # 4. serve ARPA file
  #

  class LanguageModelControlsView extends ControlsView

    actionViewClasses: [
      GenerateControlView
      GetProbabilitiesControlView
    ]

    initialize: (options) ->
      super
      @events['keydown'] = 'keyboardShortcuts'

    keyboardShortcuts: (event) ->
      console.log event.which
      ###
      switch event.which
        conso
        when 67
          @$('button.compile').click()
        when 82
          @$('button.run-tests').click()
        when 191
          @$('textarea[name=apply-down]').first().focus()
      ###

