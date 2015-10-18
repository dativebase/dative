# Tests for `FormView`
#
# Right now this just tests that interlinearize works with search patterns.
# There was a bug where doing a regex search for a space in an IGT value would
# cause single-character words to fail to be displayed.

define (require) ->

  # Note: If you don't load `UserView` before `FormView`, you'll get the
  # following error (which seems like a circular dependency thing ...)::
  #
  #     Uncaught TypeError: Cannot read property 'prototype' of undefined
  #     (enterer-field-display.coffee:1)

  globals = require '../../../scripts/utils/globals'
  ApplicationSettingsModel = require '../../../scripts/models/application-settings'
  FormModel = require '../../../scripts/models/form'
  UserView = require '../../../scripts/views/user-old'
  FormView = require '../../../scripts/views/form'

  describe '`FormView`', ->

    before ->

      @spied = [
        'interlinearize'
        '_interlinearize'
        'hideIGTFields'
        'toggleHistory'
        'disableHistoryButton'
        'fetchHistoryFormStart'
        'fetchHistoryFormEnd'
        'fetchHistoryFormFail'
        'fetchHistoryFormSuccess'
      ]
      for method in @spied
        sinon.spy FormView::, method
      spinStub = sinon.stub FormView::, 'spin', -> console.log 'spinning'
      stopSpinStub = sinon.stub FormView::, 'stopSpin', -> console.log 'stopping spinning'

      @$fixture = $ '<div id="view-fixture"></div>'

    beforeEach ->

      # Reset spies
      for method in @spied
        FormView::[method].reset()

      # Global app settings needs to be (the default) OLD one.
      applicationSettings = new ApplicationSettingsModel()
      oldLocalServer = applicationSettings.get('servers')
        .findWhere(url: "http://127.0.0.1:5000")
      applicationSettings.set 'activeServer', oldLocalServer
      globals.applicationSettings = applicationSettings

      @$fixture.empty().appendTo $('#fixtures')
      @$fixture.prepend '<div id="form"></div>'

    afterEach -> $('#fixtures').empty()

    # Return a FormView whose $el is in our fixture.
    getForm = (populate=true) ->
      if populate
        formModel = new FormModel formObject
      else
        formModel = new FormModel()
      formView = new FormView model: formModel
      formView.setElement $('#form')
      formView


    # Interlinearize
    # TODO: this should be in the test spec for `FormBaseView`
    describe '`@interlinearize`', ->

      it 'highlights a single-char regex that matches one morpheme break word',
        (done) ->
          # Simulate a search for /k/ in morpheme_break
          formView = getForm()
          formView.searchPatternsObject = morpheme_break: /((?:k))/g
          formView.render()
          x = ->
            $morphemeBreakIGTCells =
              $ '.igt-tables-container .igt-word-cell.morpheme-break-value'
            $morphemeBreakIGTCellsWithHighlight =
              $morphemeBreakIGTCells.find 'span.dative-state-highlight'
            # Three columns for a 3-word form
            expect($morphemeBreakIGTCells.length).to.equal 3
            # One column has a search match highlight in it: /k/ 'COMP' matches /k/
            expect($morphemeBreakIGTCellsWithHighlight.length).to.equal 1
            expect(formView.interlinearize).to.have.been.calledOnce
            expect(formView._interlinearize).to.have.been.calledOnce
            expect(formView.hideIGTFields).to.have.been.calledOnce
            done()
          # We need `setTimeout` because `interlinearize` uses a 1-millisecond
          # delay.
          setTimeout x, 3

      it 'highlights nothing on regex search for space character', (done) ->
        # Simulate a search for /( )/ in morpheme_break
        formView = getForm()
        formView.searchPatternsObject = morpheme_break: /((?:( )))/g
        formView.render()
        x = ->
          $morphemeBreakIGTCells =
            $ '.igt-tables-container .igt-word-cell.morpheme-break-value'
          $morphemeBreakIGTCellsWithHighlight =
            $morphemeBreakIGTCells.find 'span.dative-state-highlight'
          expect($morphemeBreakIGTCells.length).to.equal 3
          # No columns have search match highlights in them (because spaces
          # aren't represented overtly; they are the spaces between columns).
          expect($morphemeBreakIGTCellsWithHighlight.length).to.equal 0
          expect(formView.interlinearize).to.have.been.calledOnce
          expect(formView._interlinearize).to.have.been.calledOnce
          expect(formView.hideIGTFields).to.have.been.calledOnce
          done()
        setTimeout x, 3


    # HTML
    describe 'its HTML', ->

      it 'has a header which is hidden by default', ->
        formView = getForm false
        formView.render()
        expect(formView.$('div.dative-widget-header').length).to.equal 1
        expect(formView.$('div.dative-widget-header').first().is(':visible'))
          .to.be.false

      it 'has no header title text', ->
        $headerTitleDiv = $('div.dative-widget-header').first()
          .find 'div.dative-widget-header-title'
        expect($headerTitleDiv.text()).to.equal ''

      describe 'with an empty model, it ...', ->

        it 'has update, export, and settings buttons', ->
          formView = getForm false
          formView.render()
          expect(formView.$('button.update-resource').length).to.equal 1
          expect(formView.$('button.export-resource').length).to.equal 1
          expect(formView.$('button.settings').length).to.equal 1

        it 'does NOT have delete, duplicate, history, controls, or data buttons',
          ->
            formView = getForm false
            formView.render()
            expect(formView.$('button.delete-resource').length).to.equal 0
            expect(formView.$('button.duplicate-resource').length).to.equal 0
            expect(formView.$('button.resource-history').length).to.equal 0
            expect(formView.$('button.controls').length).to.equal 0
            expect(formView.$('button.file-data').length).to.equal 0

      describe 'with a non-empty model, it ...', ->

        it 'has update, export, delete, duplicate, history, and settings
          buttons', ->
            formView = getForm()
            formView.render()
            expect(formView.$('button.update-resource').length).to.equal 1
            expect(formView.$('button.delete-resource').length).to.equal 1
            expect(formView.$('button.duplicate-resource').length).to.equal 1
            expect(formView.$('button.export-resource').length).to.equal 1
            expect(formView.$('button.resource-history').length).to.equal 1
            expect(formView.$('button.settings').length).to.equal 1

        it 'does NOT have controls or data buttons', ->
          formView = getForm()
          formView.render()
          expect(formView.$('button.controls').length).to.equal 0
          expect(formView.$('button.file-data').length).to.equal 0


    describe 'History functionality', ->

      describe 'its init state', ->

        it 'starts off with no previous versions', ->
          formView = getForm()
          formView.render()
          previousVersionsDivIsEmpty =
            formView.$('div.resource-previous-versions').first().is ':empty'
          expect(formView.previousVersionModels).to.be.empty
          expect(formView.previousVersionView).to.be.empty
          expect(previousVersionsDivIsEmpty).to.be.true

        it 'involves no history event responders having been called', ->
          formView = getForm()
          expect(formView.fetchHistoryFormStart).not.to.have.been.called
          expect(formView.fetchHistoryFormEnd).not.to.have.been.called
          expect(formView.fetchHistoryFormFail).not.to.have.been.called
          expect(formView.fetchHistoryFormSuccess).not.to.have.been.called

      describe 'its “history” button', ->

        it 'triggers `@toggleHistory` when clicked', ->
          formView = getForm()
          formView.render()
          $historyButton = formView.$('button.resource-history').first()
          expect(formView.toggleHistory).not.to.have.been.called
          expect(formView.disableHistoryButton).not.to.have.been.called
          expect($historyButton.button 'option', 'disabled').to.be.false
          $historyButton.click()
          expect(formView.toggleHistory).to.have.been.calledOnce
          expect(formView.disableHistoryButton).to.have.been.calledOnce
          # Unsure why the following is failing. I must not be understanding
          # the jQuery button API ...
          #expect($historyButton.button 'option', 'disabled').to.be.true

      describe 'clicking its “history” button', ->

        it 'results in `@fetchHistoryFormStart` being called once', ->
          newFetchHistory = ->
            @trigger 'fetchHistoryFormStart'
            #@trigger 'fetchHistoryFormSuccess'
            @trigger 'fetchHistoryFormEnd'
          fetchHistoryStub = sinon.stub FormModel::, 'fetchHistory',
            newFetchHistory
          formModel = new FormModel formObject
          formView = new FormView model: formModel
          formView.setElement $('#form')
          formView.render()
          $historyButton = formView.$('button.resource-history').first()
          expect(fetchHistoryStub).not.to.have.been.called
          expect(formView.fetchHistoryFormStart).not.to.have.been.called
          #expect(formView.fetchHistoryFormSuccess).not.to.have.been.called
          expect(formView.fetchHistoryFormEnd).not.to.have.been.called
          $historyButton.click()
          expect(fetchHistoryStub).to.have.been.calledOnce
          expect(formView.fetchHistoryFormStart).to.have.been.calledOnce
          #expect(formView.fetchHistoryFormSuccess).to.have.been.calledOnce
          expect(formView.fetchHistoryFormEnd).to.have.been.calledOnce


  # An object for creating an OLD-style `FormModel` instance. Core values:
  #
  #     nitsspiyi   k    nitsspiyi
  #     /nit-ihpiyi k    nit-ihpiyi/
  #     1-dance     COMP 1-dance
  formObject = {
    "files": [],
    "syntax": "",
    "morpheme_break_ids": [
      [
        [
          [
            14639,
            "1",
            "agra"
          ]
        ],
        [
          [
            2394,
            "dance",
            "vai"
          ]
        ]
      ],
      [
        [
          [
            14957,
            "2",
            "agra"
          ],
          [
            17363,
            "IMP.PL",
            "agrb"
          ]
        ]
      ],
      [
        [
          [
            14639,
            "1",
            "agra"
          ]
        ],
        [
          [
            2394,
            "dance",
            "vai"
          ]
        ]
      ]
    ],
    "grammaticality": "",
    "datetime_modified": "2015-10-03T18:13:13",
    "morpheme_gloss_ids": [
      [
        [
          [
            14639,
            "nit",
            "agra"
          ]
        ],
        [
          [
            2394,
            "ihpiyi",
            "vai"
          ]
        ]
      ],
      [
        []
      ],
      [
        [
          [
            14639,
            "nit",
            "agra"
          ]
        ],
        [
          [
            2394,
            "ihpiyi",
            "vai"
          ]
        ]
      ]
    ],
    "date_elicited": null,
    "morpheme_gloss": "1-dance COMP 1-dance",
    "id": 25111,
    "datetime_entered": "2015-09-11T14:17:29",
    "transcription": "nitsspiyi k nitsspiyi",
    "enterer": {
      "first_name": "Joel",
      "last_name": "Dunham",
      "role": "administrator",
      "id": 1
    },
    "comments": "",
    "source": null,
    "verifier": null,
    "speaker": null,
    "speaker_comments": "",
    "status": "tested",
    "elicitor": null,
    "break_gloss_category": "nit|1|agra-ihpiyi|dance|vai k|COMP|agra nit|1|agra-ihpiyi|dance|vai",
    "tags": [],
    "elicitation_method": null,
    "translations": [
      {
        "transcription": "I danced that I danced",
        "grammaticality": "",
        "id": 25225
      }
    ],
    "syntactic_category": null,
    "phonetic_transcription": "",
    "semantics": "",
    "UUID": "5a4ec347-2b03-4146-9f4d-9736fc03620f",
    "narrow_phonetic_transcription": "",
    "syntactic_category_string": "agra-vai agra agra-vai",
    "morpheme_break": "nit-ihpiyi k nit-ihpiyi",
    "modifier": {
      "first_name": "Joel",
      "last_name": "Dunham",
      "role": "administrator",
      "id": 1
    }
  }

