define [
  './controls'
  './generate-and-compile-control'
  './apply-control'
  './apply-down-control'
  './apply-up-control'
  './serve-compiled-control'
], (ControlsView, GenerateAndCompileControlView, ApplyControlView,
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


  class MorphologyApplyUpControlView extends ApplyControlView

    direction: 'up'
    buttonText: 'Apply Up'
    resourceName: 'morphology'

    textareaTitle: ->
      if @model.get('rich_upper')
        if @model.get('rich_lower')
          "Enter a richly represented morphological analysis here and click the
            “Apply Up” button to see whether it is recognized during
            parsing."
        else
          "Enter a richly represented morphological analysis here and click the
            “Apply Up” button to see its corresponding impoverished
            representation."
      else
        if @model.get('rich_upper')
          "Enter an impoverished morphological analysis here and click the
            “Apply Up” button to see its corresponding rich representation."
        else
          "Enter an impoverished morphological analysis here and click the
            “Apply Up” button to see whether it is recognized during
            parsing."

    buttonTitle: ->
      if @model.get('rich_upper')
        if @model.get('rich_lower')
          "Enter a richly represented morphological analysis in the input on
            the left and click here to see whether it is recognized during
            generation."
        else
          "Enter a richly represented morphological analysis in the input on
            the left and click here to see its corresponding impoverished
            representation."
      else
        if @model.get('rich_upper')
          "Enter an impoverished morphological analysis in the input on the
            left and click here to see its corresponding rich representation."
        else
          "Enter an impoverished morphological analysis in the input on the
            left and click here to see whether it is recognized during
            generation."

  class MorphologyApplyDownControlView extends ApplyControlView

    direction: 'down'
    buttonText: 'Apply Down'
    resourceName: 'morphology'

    textareaTitle: ->
      if @model.get('rich_upper')
        if @model.get('rich_lower')
          "Enter a richly represented morphological analysis here and click the
            “Apply Down” button to see whether it is recognized during
            generation."
        else
          "Enter a richly represented morphological analysis here and click the
            “Apply Down” button to see its corresponding impoverished
            representation."
      else
        if @model.get('rich_upper')
          "Enter an impoverished morphological analysis here and click the
            “Apply Down” button to see its corresponding rich representation."
        else
          "Enter an impoverished morphological analysis here and click the
            “Apply Down” button to see whether it is recognized during
            generation."

    buttonTitle: ->
      if @model.get('rich_upper')
        if @model.get('rich_lower')
          "Enter a richly represented morphological analysis in the input on
            the left and click here to see whether it is recognized during
            generation."
        else
          "Enter a richly represented morphological analysis in the input on
            the left and click here to see its corresponding impoverished
            representation."
      else
        if @model.get('rich_upper')
          "Enter an impoverished morphological analysis in the input on the
            left and click here to see its corresponding rich representation."
        else
          "Enter an impoverished morphological analysis in the input on the
            left and click here to see whether it is recognized during
            generation."


  class MorphologyGenerateAndCompileControlView extends GenerateAndCompileControlView

    initialize: (options) ->
      options?.resourceName = 'morphology'
      super options


  class MorphologyControlsView extends ControlsView

    actionViewClasses: [
      MorphologyGenerateAndCompileControlView
      MorphologyApplyDownControlView
      MorphologyApplyUpControlView
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



