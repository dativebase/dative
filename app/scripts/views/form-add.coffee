define [
  'backbone'
  './base'
  './../models/form'
  './../templates/form-add'
  'multiselect'
  'jqueryelastic'
  'perfectscrollbar'
], (Backbone, BaseView, FormModel, formAddTemplate) ->

  # Form Add View
  # --------------

  # The DOM element for adding a new form
  class FormAddView extends BaseView

    template: formAddTemplate

    initialize: ->

    events:
      'change': 'setToModel' # fires when multi-select changes
      'input': 'setToModel' # fires when an input, textarea or date-picker changes
      'selectmenuchange': 'setToModel' # fires when a selectmenu changes
      'menuselect': 'setToModel' # fires when the tags multi-select changes (not working?...)

    # Set the state of the "add a form" HTML form on the model.
    setToModel: ->
      modelObject = @getModelObjectFromAddForm()
      tobesaved = new FieldDB.Document(modelObject)
      tobesaved.dbname = tobesaved.application.currentFieldDB.dbname
      tobesaved.url = tobesaved.application.currentFieldDB.url + "/"+ tobesaved.dbname
      tobesaved.save()

      @model?.set modelObject

    # Extract data in the inputs of the HTML "Add a Form" form and
    # convert them to an object
    getModelObjectFromAddForm: ->
      modelObject = {}
      for fieldObject in $('form.formAdd').serializeArray()
        # The challenge here is to take form fields with names like
        # 'translations-1.grammaticality' and use them to produce lists
        # of objects like
        # modelObject['translations'] = [..., {grammaticality: ...}]

        # First, make an object with indices as keys:
        # modelObject['translations'] = {0: ..., 1: {grammaticality: ...}}
        if fieldObject.name.split('-').length is 2
          [attr, tmp] = fieldObject.name.split '-'
          [index, subAttr] = tmp.split '.'
          if attr of modelObject
            attrVal = modelObject[attr]
          else
            attrVal = modelObject[attr] = {}
          if index of attrVal
            tmp = attrVal[index]
          else
            tmp = attrVal[index] = {}
          tmp[subAttr] = fieldObject.value
        else
          modelObject[fieldObject.name] = fieldObject.value

      # Second step is to convert the object with index keys into
      # an array.
      for attr of modelObject
        if @utils.type(modelObject[attr]) is 'object'
          array = []
          for key of (k for k of modelObject[attr]).sort()
            array.push modelObject[attr][key]
          modelObject[attr] = array

      # The tags multi-select value needs to be explicitly extracted
      modelObject.tags = $('form.formAdd select[name=tags]').val()

      modelObject

    render: ->
      params = headerTitle: 'Add a Form'
      _.extend params, @model.toJSON()
      @$el.html @template(params)
      @matchHeights()
      body = $('#dative-page-body')
      @_populateSelectFields body
      @_guify body
      @_addModel body
      @_setFocus()

    _setFocus: ->
      if @focusedElementId?
        @$("##{@focusedElementId}").first().focus()
      else
        $('#transcription').focus()


    # Add the data from the associated model to the <select>s, i.e. preserve
    # state across views. (Note that the values of textareas and text inputs
    # are inserted via the templating system.)
    _addModel: (context) ->

      # grammaticality selectmenus for translations >= 1
      for translation, index in @model.get('translations')
        if index > 0
          $('button.insertTranslationFieldButton', context).click()
        $("select[name='translations-#{index}.grammaticality']")
          .val(translation.grammaticality)
          .selectmenu 'refresh', true
        $("textarea[name='translations-#{index}.transcription']")
          .val(translation.transcription)

      # other selectmenus
      for attrName in ['grammaticality', 'elicitation_method',
        'syntactic_category', 'speaker', 'elicitor', 'verifier', 'source']
        if @model.get(attrName)
          if attrName is 'verifier'
            console.log "In _addModel; verifier should be #{@model.get(attrName)}"
          $("select[name=#{attrName}]", context)
            .val(@model.get(attrName))
            .selectmenu 'refresh', true

      # tags multiSelect (see http://loudev.com/)
      if @model.get('tags')
        $('select[name="tags"]', context)
          .multiSelect 'select', @model.get('tags')

    _guify: (context) ->
      @$('#dative-page-body').perfectScrollbar()
      @_enableAddNewTranslationFieldButton context
      selectmenuWidth = 548
      @_gramSelect = $('select.grammaticality', context).selectmenu width: 50
      $('button.insertTranslationFieldButton', context)
        .button({icons: {primary: 'ui-icon-plus'}, text: false})
      $('input[type="submit"]', context).button()
      $('input[name="date_elicited"]', context).datepicker(
        appendText: "<span style='margin: 0 10px;'>mm/dd/yyyy</span>"
        autoSize: true
      )
      $('select, input, textarea', context)
        .css "border-color", FormAddView.jQueryUIColors.defBo

      $('textarea.transcription', context)
        .focus(->
          window.scrollTo 0, 0
        )

      # CTRL + <Return> in the form submits the form
      $('form.formAdd', context).keydown((event) ->
        if event.ctrlKey and event.which is 13
          console.log 'FORM ADD IS LISTENING TO THAT RETURN!'
          event.preventDefault()
          $('input[type="submit"]', @).click()
      )

      # <Return> in a text input submits the form. The only text input is the
      # date picker.
      $('form.formAdd input[type="text"]', context)
        .keydown((event) ->
          if event.which is 13
            event.preventDefault()
            $('form.formAdd input[type="submit"]', context).click()
        )

      # Do this, otherwise jquery-elastic erratically increases textarea height ...
      $('textarea', context).css height: '16px'

    # Insert options into the select fields in the "Add a Form" form.
    _populateSelectFields: (context) ->

      # TODO: create an abstraction to hold secondary and meta-data,
      # i.e., an interface that returns users, speakers, elicitation methods, etc.
      # The API exposed should gracefully handle complications like client-side caching
      # with asynchronous RESTful sync and initial RESTful requests.
      #$.get('form/get_form_options_ajax', null, updateAddInterface, 'json');

      formAddOptions = @_fakeFormAddOptions
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

          # Populate & GUI-ify elicitation_method
          $.each(formAddOptions.elicitation_methods, () ->
            $('select[name="elicitation_method"]', context)
              .append($('<option>').attr('value', @[0]).text(@[1])))
          $('select[name="elicitation_method"]', context).selectmenu()

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
              $('#elicitation_method-button').focus()
          )

          # Populate category
          $.each(formAddOptions.categories, ->
            $('select[name="syntactic_category"]', context)
              .append($('<option>').attr('value', @[0]).text(@[1])))
          $('select[name="syntactic_category"]', context).selectmenu()

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


    # jQuery footwork to make the "+" ("add a new translation field") button work
    _enableAddNewTranslationFieldButton: (context) ->
      self = @
      $('button.insertTranslationFieldButton', context)
        .data('translationFieldCount', 0)
        .click((event) ->
          event.preventDefault()
          $(@).data('translationFieldCount', $(@).data('translationFieldCount') + 1)
          name = "translations-#{$(@).data('translationFieldCount')}"
          transcriptionId = "#{name.replace('-', '')}transcription"
          grammaticalityId = "#{name.replace('-', '')}grammaticality"
          $('<li>').appendTo($(@).closest('ul')).hide()
            .addClass("newTranslation")
            .data('index', $(@).data('translationFieldCount'))
            .append($('<label>').attr('for', "#{name}.transcription").text('Translation'))
            .append($('<select>')
              .attr(name: "#{name}.grammaticality", id: grammaticalityId)
              .addClass('grammaticality'))
            .append($('<textarea>')
              .attr(
                name: "#{name}.transcription"
                maxlength: '255'
                id: transcriptionId)
              .addClass('translation')
              .css("border-color", FormAddView.jQueryUIColors.defBo))
            .append($('<button>').addClass('removeMe')
              .attr(title: 'Remove this translation field.')
              .text('Remove Me')
              .button(icons: {primary: 'ui-icon-minus'}, text: false)
              .focus(->
                $(@).addClass('ui-state-focus'))
              .blur(->
                $(@).removeClass('ui-state-focus')))
            .slideDown('medium', ->
              # Focus the field if it was focused before
              if self._focusedElementId? is transcriptionId
                $("##{transcriptionId}").focus()
              else if self._focusedElementId? is grammaticalityId
                $("##{grammaticalityId}").focus()
            )
          $.each(self.formAddOptions.grammaticalities, ->
            $("[name=\"#{name}.grammaticality\"]")
              .append($('<option>').attr('value', @[0]).text(@[0])))
          $("[name=\"#{name}.grammaticality\"]").selectmenu width: 50
          $("[name=\"#{name}.transcription\"]").elastic(compactOnBlur: false)
            .css height: '16px'
          $('button.removeMe').click((event) ->
            event.preventDefault()
            $(@).closest('li').prev('li').find('textarea').focus()
            $(@).closest('li').slideUp('slow', ->
              $(@).remove())
          )
        )

    # Fake formAddOptions object for development purposes.
    _fakeFormAddOptions:
      grammaticalities: ['', '*', '?', '#']
      elicitation_methods: [
        [0, '']
        [1, 'volunteered']
        [2, 'translation']
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
        [0, '']
        [1, 'N']
        [2, 'V']
      ]
      speakers: [
        [0, '']
        [1, 'Jeff Bridges']
        [2, 'Leonard Cohen']
      ]
      users: [
        [0, '']
        [1, 'Mac Daddy']
        [2, 'Paddy Wagon']
        [3, 'Abba Face']
        [4, 'Zacharia Murphy']
      ]
      sources: [
        [0, '']
        [1, 'Frantz (1995)']
        [2, 'Chomsky (1965)']
      ]

