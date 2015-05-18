define [
  './controls'
  './compile-control'
  './apply-down-control'
  './run-tests-control'
  './serve-compiled-control'
], (ControlsView, CompileControlView, ApplyDownControlView,
  RunTestsControlView, ServeCompiledControlView) ->

  # Phonology Controls View
  # ----------------------------
  #
  # View for a widget containing inputs and controls for manipulating the extra
  # actions of a phonology resource. These actions are
  #
  # 1. compiling the phonology script so it can be used.
  # 2. requesting phonologization (i.e., apply down) of one or more words in an
  #    underlying representation.
  # 3. running any tests defined in the phonology.
  # 4. requesting the compiled phonology file for download.

  class PhonologyControlsView extends ControlsView

    actionViewClasses: [
      CompileControlView
      ApplyDownControlView
      RunTestsControlView
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


