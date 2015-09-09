define [
  './base'
  './../templates/filter-expression'
  'autosize'
], (BaseView, filterExpressionTemplate) ->

  # Filter Expression View
  # ----------------------
  #
  # A view for a filter expression, i.e., a set of inputs for creating a filter
  # expression for building the type of search (i.e., query) that the OLD
  # accepts. This view spawns subviews of itself for the filter expressions
  # that are contained within the filter expression that it represents. The
  # idea is to help users to build complex queries using an easy-to-understand
  # tree-like interface.
  #
  # The type of search S that the OLD accepts is a JSON array that
  # matches one of the following five rewrite rules:
  #
  #   S -> [modelName, attributeName, relationName, value]
  #   S -> [modelName, attributeName, subAttributeName, relationName, value]
  #   S -> ['not', S]
  #   S -> ['and', [S1, S2, ...]]
  #   S -> ['or', [S1, S2, ...]]
  #
  # For example, the filter expression
  #
  #   ['Form', 'transcription', 'regex', '^a']
  #
  # will return all forms whose transcription value starts with "a".
  #
  # The length-5 filter expressions are for relational attributes. For example,
  # the filter expression
  #
  #   ['Form', 'enterer', 'first_name', '=', 'Jim']
  #
  # will return all forms that were entered by a user with the first name 'Jim'.
  #
  # The length-2 filter expressions have a Boolean operator as their first
  # element and are used to conjoin, disjoin, or negate other filter
  # expressions. For example, the filter expression
  #
  #   ['not', [
  #     'and', [
  #       ['Form', 'enterer', 'first_name', '=', 'Jim'],
  #       ['Form', 'transcription', 'regex', '^a']
  #     ]
  #   ]]
  #
  # will return all forms that both were not entered by a Jim and do not have a
  # transcription that begins with "a".

  class FilterExpressionView extends BaseView

    initialize: (options) ->
      # If `@consentToHideActionWidget` is set to true, then we will hide our
      # action widget when the relevant Backbone-wide event is triggered.
      @consentToHideActionWidget = true

      @filterExpression = options.filterExpression

      # The name of the resource that this filter expression targets.
      @targetResourceName = options.targetResourceName or 'form'
      @targetResourceNameCapitalized = @utils.capitalize @targetResourceName

      # We remember the correlations between attributes and subattributes so if
      # we reselect a previously selected attribute we can restore its previous
      # subattribute value.
      if @filterExpression.length is 5
        @subattributeMemoryMap[@filterExpression[1]] = @filterExpression[2]

      # `@options` is an object of options for building filter expressions,
      # i.e., the attributes of the resources being searched and the attributes
      # of their relational attributes and the possible relations.
      @options = options.options

      @initializeFilterExpressionSubviews()

    # This is the primary or typical attribute of the resource being searched.
    # This is simply used to create the default filter expression values.
    primaryAttribute: 'transcription'

    # Instantiate a new `FilterExpressionView` for each sub-filter-expression
    # that we may have. These are stored in `@filterExpressionSubviews`.
    initializeFilterExpressionSubviews: ->
      @filterExpressionSubviews = []
      if @filterExpression[0] in ['and', 'or']
        for subFilterExpression in @filterExpression[1]
          filterExpressionSubview =
            @getNewFilterExpressionView subFilterExpression
          @filterExpressionSubviews.push filterExpressionSubview
      else if @filterExpression[0] is 'not'
        filterExpressionSubview =
          @getNewFilterExpressionView @filterExpression[1]
        @filterExpressionSubviews.push filterExpressionSubview

    subattributeMemoryMap: {}

    listenToEvents: ->
      super
      @listenTo Backbone, 'filterExpressionsHideActionWidgets',
        @filterExpressionsHideActionWidgets
      @listenTo Backbone, 'filterExpressionDestroyed', @actionButtonsVisibility
      @listenToSubviews()

    listenToSubviews: ->
      for filterExpressionSubview in @filterExpressionSubviews
        @listenToSubview filterExpressionSubview

    listenToSubview: (subview) ->
      @listenTo subview, 'destroyMe', @destroyFilterExpressionSubview
      @listenTo subview, 'changed', @triggerChanged

    triggerChanged: -> @trigger 'changed'

    # Destroy a specific filter expression subview: remove it from our "model"
    # (i.e., our `@filterExpression` array) and from our array of subviews.
    destroyFilterExpressionSubview: (filterExpressionSubview) ->
      operator = @filterExpression[0]
      if operator in ['and', 'or', 'not']
        if operator is 'not' or
        (operator in ['and', 'or'] and @filterExpression[1].length is 1)
          Backbone.trigger 'cantDeleteFilterExpressionOnlyChild'
        else
          filterExpressionSubview.$el.fadeOut
            complete: =>
              filterExpressionSubview.close()
              @closed filterExpressionSubview
              index = @filterExpressionSubviews.indexOf filterExpressionSubview
              @filterExpressionSubviews.splice index, 1
              if @filterExpression[0] is 'not'
                @filterExpression.pop 1
              else
                @filterExpression[1].splice index, 1
              @actionButtonsVisibility()
              @triggerChanged()

    # Hide our action widget. `@consentToHideActionWidget` will only be false if
    # this view is the one who triggered the event that causes this method to
    # be called.
    filterExpressionsHideActionWidgets: ->
      if @consentToHideActionWidget then @hideActionWidget()
      @consentToHideActionWidget = true

    events:
      'click button.operator':           'toggleActionWidget'
      'click button.make-and':           'makeOperatorAnd'
      'click button.conjoin':            'conjoin'
      'click button.make-or':            'makeOperatorOr'
      'click button.disjoin':            'disjoin'
      'click button.negate':             'negate'
      'click button.make-not-not':       'removeNotOperator'
      'click button.destroy':            'destroyFilterExpression'
      'click button.add-operand':        'addOperand'
      'selectmenuchange .attribute':     'attributeChanged'
      'selectmenuchange .sub-attribute': 'subattributeChanged'
      'selectmenuchange .relation':      'relationChanged'
      'input .value':                    'valueChanged'

    valueChanged: (event) ->
      @stopEvent event
      $valueTextarea = @$('textarea.value').first()
      value = $valueTextarea.val()
      if @filterExpression.length is 5
        if @filterExpression[3] is 'in'
          @filterExpression[4] = @jsonParse value
        else
          @filterExpression[4] = value
      else
        if @filterExpression[2] is 'in'
          @filterExpression[3] = @jsonParse value
        else
          @filterExpression[3] = value
      @triggerChanged()

    jsonParse: (value) ->
      try
        JSON.parse value
      catch
        value

    relationChanged: (event) ->
      @stopEvent event
      $relationSelect = @$('select.relation').first()
      relation = $relationSelect.val()
      if @filterExpression.length is 5
        @filterExpression[3] = relation
      else
        @filterExpression[2] = relation
      @triggerChanged()

    attributeChanged: (event) ->
      @stopEvent event
      @syncAttributeSubattributeSelects()
      attribute = @$('select.attribute').first().val()
      @filterExpression[1] = attribute
      $subAttributeSelect = @$('select.sub-attribute').first()
      $subAttributeSelectmenu = @$('.ui-selectmenu-button.sub-attribute').first()
      if $subAttributeSelectmenu.is ':visible'
        subAttribute = $subAttributeSelect.val()
        if @filterExpression.length is 5
          @filterExpression[2] = subAttribute
        else
          @filterExpression.splice 2, 0, subAttribute
      else
        if @filterExpression.length is 5
          @filterExpression.splice 2, 1
      @triggerChanged()

    # Alter `@filterExpression` so that it accords with the DOM representation
    # of the subattribute.
    #  model   attribute        subattribute  relation value
    # ['Form', 'enterer',       'first_name', 'is',    'John']
    #  0       1                2             3        4
    #
    #  model   attribute        relation      value
    # ['Form', 'transcription', 'is',         'John']
    #  0       1                2             3
    subattributeChanged: (event, triggerChanged=true) ->
      if event then @stopEvent event
      $subAttributeSelect = @$('select.sub-attribute').first()
      $subAttributeSelectmenu = @$('.ui-selectmenu-button.sub-attribute').first()
      if $subAttributeSelectmenu.is ':visible'
        subAttribute = $subAttributeSelect.val()
        @subattributeMemoryMap[@filterExpression[1]] = subAttribute
        if @filterExpression.length is 5
          @filterExpression[2] = subAttribute
        else
          @filterExpression.splice 2, 0, subAttribute
        if triggerChanged then @triggerChanged()
      else
        if @filterExpression.length is 5
          @filterExpression.splice 2, 1

    # Synchronize the attribute and subattribute selectmenus.
    # That is, if attribute is relational (i.e., valuated by reference to
    # another object), then the sub-attribute select needs to be visible and it
    # needs to be populated with the sub-attribute options relevant to its
    # parent relational attribute.
    # TODO: this view should remember the last selected sub-attribute of a
    # given attribute.
    syncAttributeSubattributeSelects: ->
      attribute = @$('select.attribute').first().val()
      subattributes = @subattributes()
      if attribute of subattributes
        # If `attribute` is relational, we rebuild its selectmenu.
        $subAttributeSelect = @$('select.sub-attribute').first()
        $subAttributeSelect.html ''

        # Note that we remember the last attribute-subattribute correlation and
        # implement that here. If there is no last correlation, we use the
        # default subattribute for the given attribute, if there is one.
        valueThatShouldBeSelected = null
        if attribute of @subattributeMemoryMap
          valueThatShouldBeSelected =
            @subattributeMemoryMap[attribute]
        else if attribute of @subattributeDefaults
          valueThatShouldBeSelected = @subattributeDefaults[attribute]
        for subattribute in subattributes[attribute].sort()
          if valueThatShouldBeSelected and
          valueThatShouldBeSelected is subattribute
            $subAttributeSelect.append "<option value='#{subattribute}'
              selected>#{@utils.snake2regular subattribute}</option>"
          else
            $subAttributeSelect.append "<option value='#{subattribute}'
              >#{@utils.snake2regular subattribute}</option>"

        # Rebuild the selectmenu machinery.
        $subAttributeSelect
          .selectmenu 'destroy'
          .selectmenu()
          .each (index, element) =>
            @transferClassAndTitle @$(element) # so we can tooltipify the selectmenu
        @$('.ui-selectmenu-button.sub-attribute').first()
          .tooltip
            content: "select a sub-attribute for the
              #{@utils.snake2regular(attribute)}"

      else
        # If `attribute` is non-relational, we hide the sub-attribute selectmenu.
        @$('select.sub-attribute').first().hide()
        @$('.ui-selectmenu-button.sub-attribute').first().hide()

    # If this filter expression has a boolean (and/or) as its non-terminal, add
    # a new coordinand, i.e., a new filter expression under the scope of the
    # boolean. If there is a "not" as the non-terminal, add an
    # operand/complement under its scope. Note: this button should only be
    # visible/available if the non-terminal is a boolean OR if the non-terminal
    # is a stranded negation.
    addOperand: (event) ->
      @stopEvent event
      @hideActionWidgetAnimate()
      operator = @filterExpression[0]
      if operator in ['or', 'and'] or
      (operator is 'not' and @filterExpression.legnth is 1)
        newFilterExpression = @getDefaultFilterExpression()
        if operator in ['or', 'and']
          @filterExpression[1].push newFilterExpression
        else if operator is 'not'
          @filterExpression.push newFilterExpression
        filterExpressionSubview =
          @getNewFilterExpressionView newFilterExpression
        @filterExpressionSubviews.push filterExpressionSubview
        @renderFilterExpressionSubview filterExpressionSubview, true
        @listenToSubview filterExpressionSubview
        @triggerChanged()

    getDefaultFilterExpression: ->
      [@targetResourceNameCapitalized , @primaryAttribute, 'like', '%']

    # Change the operator to a boolean, i.e., 'and' or 'or'.
    makeOperatorBoolean: (boolean) ->
      booleans = ['or', 'and']
      @hideActionWidgetAnimate()
      if @filterExpression[0] in booleans
        @filterExpression[0] = boolean
        @$('button.operator').first()
          .button 'option', 'label', boolean
          .button 'refresh'
        @actionButtonsVisibility()

    # Add a boolean ('and' or 'or') with scope over this filter expression.
    coordinate: (boolean) ->
      booleans = ['or', 'and']
      @hideActionWidgetAnimate()
      @coordinateFilterExpression boolean
      @$el.fadeOut
        complete: =>
          for subview in @filterExpressionSubviews
            subview.close()
          @initializeFilterExpressionSubviews()
          @$el.empty()
          @render()
          @$el.fadeIn
            complete: =>
              @$('button, .ui-selectmenu-button, .textarea').first().focus()
      @triggerChanged()

    # Add an "and" with scope over this filter expression.
    conjoin: (event) ->
      @stopEvent event
      @coordinate 'and'

    # Add an "or" with scope over this filter expression.
    disjoin: (event) ->
      @stopEvent event
      @coordinate 'or'

    # Change the operator of this filter expression to 'and'.
    makeOperatorAnd: (event) ->
      @stopEvent event
      @makeOperatorBoolean 'and'

    # Change the operator of this filter expression to 'or'.
    makeOperatorOr: (event) ->
      @stopEvent event
      @makeOperatorBoolean 'or'

    # Change the operator of this filter expression to 'not'.
    negate: (event) ->
      @stopEvent event
      @hideActionWidgetAnimate()
      @negateFilterExpression()
      @$el.fadeOut
        complete: =>
          for subview in @filterExpressionSubviews
            subview.close()
          @initializeFilterExpressionSubviews()
          @$el.empty()
          @render()
          @$el.fadeIn
            complete: =>
              @$('button, .ui-selectmenu-button, .textarea').first().focus()
      @triggerChanged()

    # Remove the "not" operator from this filter expression.
    removeNotOperator: (event) ->
      @stopEvent event
      @hideActionWidgetAnimate()
      @removeNegationFromFilterExpression()
      @$el.fadeOut
        complete: =>
          for subview in @filterExpressionSubviews
            subview.close()
          @initializeFilterExpressionSubviews()
          @$el.empty()
          @render()
          @$el.fadeIn
            complete: =>
              @$('button, .ui-selectmenu-button, .textarea').first().focus()
      @triggerChanged()

    # Change our filter expression array so that it begins with a 'not'.
    negateFilterExpression: ->
      @filterExpression.unshift (x for x in @filterExpression)
      @filterExpression.unshift 'not'
      while @filterExpression.length > 2
        @filterExpression.pop()

    # Change our filter expression array so that it NO LONGER begins with a
    # 'not'.
    removeNegationFromFilterExpression: ->
      for element in @filterExpression[1]
        @filterExpression.push element
      @filterExpression.shift()
      @filterExpression.shift()

    # Change our filter expression array so that it begins with an 'and' or an
    # 'or'. Here we have to shift things in the array around so that we're in a
    # proper and/or configuration, i.e., go from FE to ['and/or', [FE]],
    # all while not replacing any existing arrays; that is, we need to keep
    # the whole filter expression array intact, no copying.
    coordinateFilterExpression: (coordinator) ->
      @filterExpression.unshift [(x for x in @filterExpression)]
      @filterExpression.unshift coordinator
      while @filterExpression.length > 2
        @filterExpression.pop()

    # Destroy this filter expression. Note: we trigger a `destroyMe` event and
    # let the parent `FilterExpression` view handle most of the destruction.
    destroyFilterExpression: (event) ->
      @stopEvent event
      @hideActionWidgetAnimate()
      @trigger 'destroyMe', @

    # Toggle the action widget, i.e., the <div> full of buttons that pops up
    # when you click on an "operator" button.
    toggleActionWidget: (event) ->
      if event then @stopEvent event
      $actionWidgetContainer =
        @$('div.filter-expression-action-widget-container').first()
      if $actionWidgetContainer.is ':visible'
        $actionWidgetContainer.slideUp('fast')
        @$('button.operator').first()
          .tooltip
            content: 'click here to reveal buttons for changing this node.'
            position: @tooltipPositionLeft('-20')
      else
        @consentToHideActionWidget = false
        Backbone.trigger 'filterExpressionsHideActionWidgets'
        $actionWidgetContainer
          .slideDown('fast')
          .find('button').first().focus()
        @$('button.operator').first()
          .tooltip
            content: 'click here to hide the buttons for changing this node.'
            position: @tooltipPositionLeft('-20')

    hideActionWidget: ->
      @$('div.filter-expression-action-widget-container').first().hide()

    hideActionWidgetAnimate: ->
      @$('div.filter-expression-action-widget-container').first()
        .slideUp('fast')

    # Initialize a new `FilterExpressionView` with `subFilterExpression` as its
    # filter expression.
    getNewFilterExpressionView: (subFilterExpression) ->
      new @constructor(
        model: @model
        targetResourceName: @targetResourceName
        filterExpression: subFilterExpression
        options: @options
        rootNode: false
      )

    template: filterExpressionTemplate

    getAttributes: ->
      try
        key = "#{@targetResourceName}_search_parameters"
        attrs = @options[key].attributes
        (x for x in _.keys(attrs).sort() \
        when x not in ['morpheme_break_ids', 'morpheme_gloss_ids'])
      catch
        []

    render: ->
      context =
        filterExpression: @filterExpression
        options: @options
        attributes: @getAttributes()
        subattributes: @subattributes() # TODO: we have to do this ourselves! The OLD should provide it though...
        relations: @getRelations @options
        snake2regular: @utils.snake2regular
        pluralize: @utils.pluralize
      @$el.html @template(context)
      @bordercolorify()
      $filterExpressionTable = @$('.filter-expression-table').first()
      @selectmenuify $filterExpressionTable
      if @filterExpression.length is 4
        @$('select.sub-attribute').hide()
        @$('.ui-selectmenu-button.sub-attribute').hide()
      $filterExpressionTable
        .find('textarea').autosize().end()
        .find('button').button().end()
        .find('.dative-tooltip.operator')
          .tooltip position: @tooltipPositionLeft('-20')
          .end()
        .find('.dative-tooltip').not('.operator')
          .tooltip position:
            my: 'left bottom'
            at: 'left top-20'
            collision: 'flipfit'
      @renderFilterExpressionSubviews()
      @hideActionWidget()
      @actionButtonsVisibility()
      @listenToEvents()
      @

    # We filter out some of the relations exposed by the OLD; this is because
    # some of them are redundant and have ugly names, e.g., ugly "__ne__" is
    # co-referential with "!=" and "regexp" is the same as "regex".
    getRelations: (options) ->
      try
        key = "#{@targetResourceName}_search_parameters"
        relations = _.keys options[key].relations
        (r for r in relations when r isnt 'regexp' and '_' not in r)
      catch
        []

    # Make <select>s into jQuery selectmenus.
    selectmenuify: ($context) ->
      $context.find('select')
        .selectmenu width: 'auto'
        .each (index, element) =>
          @transferClassAndTitle @$(element) # so we can tooltipify the selectmenu

    # Show/hide various action buttons for the non-terminal node of this filter
    # expression, depending on its state.
    actionButtonsVisibility: ->
      myOperator = @filterExpression[0]
      $actionWidget = @$('.filter-expression-action-widget').first()
      @hideButtonForExistingState myOperator, $actionWidget
      if myOperator in ['and', 'or']
        if @filterExpression[1].length > 1
          $actionWidget.find('button.destroy').hide()
        else
          $actionWidget.find('button.destroy').show()
        $actionWidget.find('button.add-operand').show()
        $actionWidget.find('button.make-not-not').hide()
        if myOperator is 'and'
          $actionWidget.find('button.make-and').hide()
          $actionWidget.find('button.make-or').show()
        else
          $actionWidget.find('button.make-or').hide()
          $actionWidget.find('button.make-and').show()
      else
        $actionWidget.find('button.make-or').hide()
        $actionWidget.find('button.make-and').hide()
        if myOperator is 'not'
          $actionWidget.find('button.make-not-not').show()
          if @filterExpression.length is 1
            $actionWidget.find('button.add-operand').show()
        else
          $actionWidget.find('button.make-not-not').hide()
          $actionWidget.find('button.add-operand').hide()

    # Hide the button for changing to the current state. That is, if this is an
    # 'and' node, we don't want to show the "make me an 'and' node" button.
    hideButtonForExistingState: (myOperator, $actionWidget=null) ->
      $actionWidget =
        $actionWidget or @$('.filter-expression-action-widget').first()
      operators = ['and', 'or', 'not', '']
      for operator in operators
        if myOperator is operator or myOperator not in operators
          $actionWidget
            .find("button.make-#{operator}").hide().end()
            .find('button').not(".make-#{operator}").show()

    renderFilterExpressionSubviews: ->
      for filterExpressionSubview in @filterExpressionSubviews
        @renderFilterExpressionSubview filterExpressionSubview

    renderFilterExpressionSubview: (filterExpressionSubview, animate=false) ->
      @$('.filter-expression-operand').first()
        .append filterExpressionSubview.render().el
      if animate
        filterExpressionSubview.$el
          .hide()
          .fadeIn
            complete: =>
              filterExpressionSubview
                .$('button, .ui-selectmenu-button, .textarea').first().focus()
      @rendered filterExpressionSubview

    # Make the border colors match the jQueryUI theme.
    bordercolorify: ->
      @$('.filter-expression-table').first().find('textarea, input')
        .css "border-color", @constructor.jQueryUIColors().defBo
      @$('.filter-expression-action-widget').first()
        .css
          "border-color": @constructor.jQueryUIColors().defBo
          "background-color": @constructor.jQueryUIColors().defCo

    # TODO: the OLD should be supplying all of this information. We should
    # not have to specify it here.
    subattributes: ->
      switch @targetResourceName
        when 'form' then @formSubattributes()
        when 'file' then @fileSubattributes()
        when 'collection' then @collectionSubattributes()
        when 'language' then @languageSubattributes()

    languageSubattributes: -> {}

    collectionSubattributes: ->
      elicitor: @userAttributes
      enterer: @userAttributes
      modifier: @userAttributes
      speaker: @speakerAttributes
      tags: @tagAttributes
      files: @fileAttributes
      source: @sourceAttributes

    fileSubattributes: ->
      elicitor: @userAttributes
      enterer: @userAttributes
      speaker: @speakerAttributes
      parent_file: @fileAttributes
      tags: @tagAttributes
      forms: @formAttributes
      collections: @collectionAttributes

    formSubattributes: ->
      collections: @collectionAttributes
      corpora: [
        'content'
        'datetime_entered'
        'datetime_modified'
        'description'
        'enterer'
        'files'
        'form_search'
        'id'
        'modifier'
        'name'
        'tags'
        'UUID'
      ]
      elicitation_method: [
        'id'
        'name'
        'description'
        'datetime_modified'
      ]
      elicitor: @userAttributes
      enterer: @userAttributes
      modifier: @userAttributes
      files: @fileAttributesNonRelational
      memorizers: @userAttributes
      source: @sourceAttributes
      speaker: @speakerAttributes
      syntactic_category: [
        'datetime_modified'
        'description'
        'id'
        'name'
        'type'
      ]
      tags: @tagAttributes
      translations: [
        'datetime_modified'
        'form_id'
        'grammaticality'
        'id'
        'transcription'
      ]
      verifier: @userAttributes

    sourceAttributes: [
      'id'
      'file_id'
      'file'
      'crossref_source_id'
      'crossref_source'
      'datetime_modified'
      'type'
      'key'
      'address'
      'annote'
      'author'
      'booktitle'
      'chapter'
      'crossref'
      'edition'
      'editor'
      'howpublished'
      'institution'
      'journal'
      'key_field'
      'month'
      'note'
      'number'
      'organization'
      'pages'
      'publisher'
      'school'
      'series'
      'title'
      'type_field'
      'url'
      'volume'
      'year'
      'affiliation'
      'abstract'
      'contents'
      'copyright'
      'ISBN'
      'ISSN'
      'keywords'
      'language'
      'location'
      'LCCN'
      'mrnumber'
      'price'
      'size'
    ]

    userAttributes: [
      'id'
      'first_name'
      'last_name'
      'email'
      'affiliation'
      'role'
      'markup_language'
      'page_content'
      'html'
      'input_orthography'
      'output_orthography'
      'datetime_modified'
    ]

    speakerAttributes: [
      'id'
      'first_name'
      'last_name'
      'dialect'
      'markup_language'
      'page_content'
      'html'
      'datetime_modified'
    ]

    fileAttributesNonRelational: [
      'id'
      'date_elicited'
      'datetime_entered'
      'datetime_modified'
      'filename'
      'name'
      'lossy_filename'
      'MIME_type'
      'size'
      'description'
      'utterance_type'
      'url'
      'password'
      'start'
      'end'
    ]

    fileAttributes: [
      'id'
      'date_elicited'
      'datetime_entered'
      'datetime_modified'
      'filename'
      'name'
      'lossy_filename'
      'MIME_type'
      'size'
      'description'
      'utterance_type'
      'url'
      'password'
      'enterer'
      'elicitor'
      'speaker'
      'tags'
      'forms'
      'parent_file'
      'start'
      'end'
    ]

    tagAttributes: [
      'id'
      'name'
      'description'
      'datetime_modified'
    ]

    formAttributes: [
      'files',
      'elicitor'
      'break_gloss_category'
      'tags'
      'elicitation_method'
      'translations'
      'syntax'
      'memorizers'
      'syntactic_category'
      'grammaticality'
      'syntactic_category_string'
      'datetime_modified'
      'date_elicited'
      'phonetic_transcription'
      'morpheme_gloss'
      'id'
      'semantics'
      'datetime_entered'
      'UUID'
      'narrow_phonetic_transcription'
      'transcription'
      'corpora'
      'enterer'
      'comments'
      'source'
      'verifier'
      'speaker'
      'morpheme_break'
      'collections'
      'speaker_comments'
    ]

    collectionAttributes: [
      'id'
      'UUID'
      'title'
      'type'
      'url'
      'description'
      'markup_language'
      'contents'
      'contents_unpacked'
      'html'
      'date_elicited'
      'datetime_entered'
      'datetime_modified'
      'speaker'
      'source'
      'elicitor'
      'enterer'
      'modifier'
      'tags'
      'files'
    ]

    # Maps attributes to the default subattribute that should be displayed when
    # the attribute is selected.
    subattributeDefaults:
      collections: 'title'
      corpora: 'name'
      elicitation_method: 'name'
      elicitor: 'last_name'
      enterer: 'last_name'
      files: 'filename'
      forms: 'transcription'
      memorizers: 'last_name'
      parent_file: 'filename'
      source: 'author'
      speaker: 'last_name'
      syntactic_category: 'name'
      tags: 'name'
      translations: 'transcription'
      verifier: 'last_name'
      modifier: 'last_name'

