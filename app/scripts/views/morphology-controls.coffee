define [
  './controls'
  './generate-and-compile-control'
  './apply-down-control'
  './apply-up-control'
  './serve-compiled-control'
], (ControlsView, GenerateAndCompileControlView,
  ApplyDownControlView, ApplyUpControlView, ServeCompiledControlView) ->

  # Morphology Controls View
  # ----------------------------
  #
  # View for a widget containing inputs and controls for manipulating the extra
  # actions of a morphology resource. These actions are
  #
  # 1. generating the morphology FST script from the specified corpora.
  # 2. generating the script and compiling it.
  # 3. requesting apply down conversion of a word or list of underlying forms.
  # 4. requesting apply up conversion of a word or list of surface forms.
  # 5. requesting the compiled morphology file for download.

  class MorphologyGenerateAndCompileControlView extends GenerateAndCompileControlView

    initialize: (options) ->
      options?.resourceName = 'morphology'
      super options

  class MorphologyControlsView extends ControlsView

    actionViewClasses: [
      MorphologyGenerateAndCompileControlView
      ApplyDownControlView
      ApplyUpControlView
      ServeCompiledControlView
    ]

    initialize: (options) ->
      super
      @events['keydown'] = 'keyboardShortcuts'

    keyboardShortcuts: (event) ->
      switch event.which
        when 67
          @$('button.compile').click()
        when 82
          @$('button.run-tests').click()
        when 191
          @$('textarea[name=apply-down]').first().focus()



