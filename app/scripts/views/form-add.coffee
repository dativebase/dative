define [
  'jquery',
  'lodash',
  'backbone',
  'views/basepage'
], ($, _, Backbone, BasePageView) ->

  # Form Add View
  # --------------

  # The DOM element for adding a new form
  class FormAddView extends BasePageView

    template: JST['app/scripts/templates/form-add.ejs']

    initialize: ->
      @initialized = true
      #@listenTo @model, 'change', @render
      #@listenTo @model, 'destroy', @remove
      #@render()

    render: ->
      params =
        headerTitle: 'Add a Form'
      @$el.html @template(params)
      @matchHeights()

      body = $('#old-page-body')

      # Populate Form Add Interface Select Fields. That is, populate the select
      # fields of the Add Form interface with options received from the server
      # via Ajax.
      @populateAddInterfaceSelectFields body

      @enableAddNewTranslationFieldButton body

      selectmenuWidth = 548
      $('select.grammaticality', body).selectmenu width: 50
      $('button.insertTranslationFieldButton', body)
        .button({icons: {primary: 'ui-icon-plus'}, text: false})
      $('input[type="submit"]', body).button()
      #$('select[name="elicitationMethod"]', body).selectmenu width: selectmenuWidth
      #$('select[name="tags"]', body).hide()
      #$('select[name="syntacticCategory"]', body).selectmenu width: selectmenuWidth
      #$('select[name="speaker"]', body).selectmenu width: selectmenuWidth
      #$('select[name="elicitor"]', body).selectmenu width: selectmenuWidth
      #$('select[name="verifier"]', body).selectmenu width: selectmenuWidth
      #$('select[name="source"]', body).selectmenu width: 200
      $('input[name="dateElicited"]', body).datepicker(
        appendText: "<span style='margin: 0 10px;'>mm/dd/yyyy</span>"
        autoSize: true
      )
      $('select, input, textarea', body)
        .css("border-color", @parent.jQueryUIColors.defBo)

      # TODO: figure out what this does ...
      $('textarea.transcription', body)
        .focus(->
          window.scrollTo(0, 0)
        )

      # CTRL + <Return> in the form submits the form
      $('form.formAdd', body).keydown((event) ->
        if event.ctrlKey and event.which is 13
          event.preventDefault()
          $('input[type="submit"]', @).click()
      )

      # <Return> in a text input submits the form. The only text input is the
      # date picker.
      $('form.formAdd input[type="text"]', body)
        .keydown((event) ->
          if event.which is 13
            event.preventDefault()
            $('form.formAdd input[type="submit"]', body).click()
        )

      $('#transcription').focus()

      # Do this, otherwise jquery-elastic erratically increases textarea height ...
      $('textarea', body).css height: '16px'

    populateAddInterfaceSelectFields: (context) ->
      #$.get('form/get_form_options_ajax', null, updateAddInterface, 'json');

      # Fake formAddOptions object for testing ...
      formAddOptions =
        grammaticalities: ['', '*', '?', '#']
        elicitationMethods: [
          [0, 'volunteered']
          [1, 'translation']
        ]
        tags: [
          [0, 'imperfective']
          [1, 'habitual']
          [2, 'frog']
          [3, 'banana']
          [4, 'helicopter']
          [5, 'fish']
          [6, 'spoon']
          [7, 'politician']
          [8, 'freak']
          [9, 'dingo']
        ]
        categories: [
          [0, 'N']
          [1, 'V']
        ]
        speakers: [
          [0, 'Jeff Bridges']
          [1, 'Leonard Cohen']
        ]
        users: [
          [0, 'Mac Daddy']
          [1, 'Paddy Wagon']
        ]
        sources: [
          [0, 'Frantz (1995)']
          [1, 'Chomsky (1965)']
        ]

      updateAddInterface = (formAddOptions, statusText) =>
        if statusText is 'success'
          # Save the formAddOptions for later,
          #  e.g., for additional translation grammaticality select fields
          @formAddOptions = formAddOptions

          # Make all of the textareas elastic
          $('textarea', context).elastic compactOnBlur: false

          # Populate grammaticality
          $.each(formAddOptions.grammaticalities, () ->
            $('select.grammaticality', context)
              .append($('<option>').attr('value', @[0]).text(@[0])))
          $('select.grammaticality', context).selectmenu width: 50

          # Populate & GUI-ify elicitationMethod
          $.each(formAddOptions.elicitationMethods, () ->
            $('select[name="elicitationMethod"]', context)
              .append($('<option>').attr('value', @[0]).text(@[1])))
          $('select[name="elicitationMethod"]', context).selectmenu()

          # Populate & GUI-ify tags
          tagsSelect = $('select[name="tags"]', context)
          $.each(formAddOptions.tags, () ->
            tagsSelect.append($('<option>').attr('value', @[0]).text(@[1])))
          tagsSelect.multiSelect()

          # Make the the SHIFT+TAB event on the multiselect move focus to
          # the elicitation method selectmenu
          # BUG: why is this putting focus on speaker comments?
          $('div.tags-multiselect').on('keydown', (e) ->
            if e.shiftKey and e.which is 9
              $('#elicitationMethod-button').focus()
          )

          # Populate category
          $.each(formAddOptions.categories, ->
            $('select[name="syntacticCategory"]', context)
              .append($('<option>').attr('value', @[0]).text(@[1])))
          $('select[name="syntacticCategory"]', context).selectmenu()

          # Populate speaker
          $.each(formAddOptions.speakers, ->
            $('select[name="speaker"]', context)
              .append($('<option>').attr('value', @[0]).text(@[1])))
          $('select[name="speaker"]', context).selectmenu()

          # Populate elicitor & verifier
          $.each(formAddOptions.users, ->
            $('select[name="elicitor"], select[name="verifier"]', context)
              .append($('<option>').attr('value', @[0]).text(@[1])))
          $('select[name="elicitor"]', context).selectmenu()
          $('select[name="verifier"]', context).selectmenu()

          # Populate source
          $.each(formAddOptions.sources, ->
            $('select[name="source"]', context)
              .append($('<option>').attr('value', @[0]).text(@[1])))
          $('select[name="source"]', context).selectmenu()

      updateAddInterface(formAddOptions, "success")


    enableAddNewTranslationFieldButton: (context) ->
      self = @
      $('button.insertTranslationFieldButton', context)
        .data('translationFieldCount', 0)
        .click((event) ->
          event.preventDefault()
          $(@).data('translationFieldCount', $(@).data('translationFieldCount') + 1)
          name = 'translations-' + $(@).data('translationFieldCount')
          $('<li>').appendTo($(@).closest('ul')).hide()
            .addClass("newTranslation")
            .data('index', $(@).data('translationFieldCount'))
            .append($('<label>').attr('for', name + '.translation').text('Translation'))
            .append($('<select>')
              .attr(name: name + '.grammaticality')
              .addClass('grammaticality'))
            .append($('<textarea>')
              .attr(name: name + '.translation', maxlength: '255')
              .addClass('translation')
              .css("border-color", self.parent.jQueryUIColors.defBo))
            .append($('<button>').addClass('removeMe')
              .attr(title: 'Remove this translation field.')
              .text('Remove Me')
              .button(icons: {primary: 'ui-icon-minus'}, text: false)
              .focus(->
                $(@).addClass('ui-state-focus'))
              .blur(->
                $(@).removeClass('ui-state-focus')))
            .slideDown('medium')
          $.each(self.formAddOptions.grammaticalities, ->
            $('[name="' + name + '.grammaticality"]')
              .append($('<option>').attr('value', @[0]).text(@[0])))
          $('[name="' + name + '.grammaticality"]').selectmenu({width: 50})
          $('[name="' + name + '.translation"]').elastic({compactOnBlur: false})
            .css height: '16px'
          $('button.removeMe').click((event) ->
            event.preventDefault()
            $(@).closest('li').prev('li').find('textarea').focus()
            $(@).closest('li').slideUp('slow', ->
              $(@).remove())
          )
        )

