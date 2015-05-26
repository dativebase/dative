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

      # `@options` is an object of options for building filter expressions,
      # i.e., the attributes of forms and the attributes of their relational
      # attributes and the possible relations.
      @options = options.options

      @initializeFilterExpressionSubviews()

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

    listenToEvents: ->
      super
      @listenTo Backbone, 'filterExpressionsHideActionWidgets',
        @filterExpressionsHideActionWidgets
      @listenTo Backbone, 'filterExpressionDestroyed', @actionButtonsVisibility
      @listenToSubviews()

    listenToSubviews: ->
      for filterExpressionSubview in @filterExpressionSubviews
        @listenTo filterExpressionSubview, 'destroyMe',
          @destroyFilterExpressionSubview

    # Destroy a specific filter expression subview: remove it from our "model"
    # (i.e., our `@filterExpression` array) and from our array of subviews.
    destroyFilterExpressionSubview: (filterExpressionSubview) ->
      if @filterExpression[0] in ['and', 'or']
        filterExpressionSubview.close()
        @closed filterExpressionSubview
        index = @filterExpressionSubviews.indexOf filterExpressionSubview
        @filterExpressionSubviews.splice index, 1
        @filterExpression[1].splice index, 1
        @actionButtonsVisibility()

    # Hide our action widget. `@consentToHideActionWidget` will only be false if
    # this view is the one who triggered the event that causes this method to
    # be called.
    filterExpressionsHideActionWidgets: ->
      if @consentToHideActionWidget then @hideActionWidget()
      @consentToHideActionWidget = true

    events:
      'click button.operator':       'toggleActionWidget'
      'click button.make-and':       'makeOperatorAnd'
      'click button.make-or':        'makeOperatorOr'
      'click button.make-not':       'makeOperatorNot'
      'click button.make-':          'emptyOperator'
      'click button.destroy':        'destroyFilterExpression'
      'click button.add-coordinand': 'addCoordinand'
      'selectmenuchange .attribute': 'attributeChanged'

    attributeChanged: (event) ->
      @stopEvent event
      # TODO: change/create/destroy subattribute selectmenu based on this ...
      console.log 'attributeChanged called'

    # If this filter expression has a boolean (and/or) as its non-terminal, add
    # a new coordinand, i.e., a new filter expression under the scope of the
    # boolean. Note: this button should only be visible/available if the
    # non-terminal is a boolean.
    addCoordinand: (event) ->
      @stopEvent event
      booleans = ['or', 'and']
      @hideActionWidgetAnimate()
      if @filterExpression[0] in booleans
        newFilterExpression = @getDefaultFilterExpression()
        @filterExpression[1].push newFilterExpression
        filterExpressionSubview =
          @getNewFilterExpressionView newFilterExpression
        @filterExpressionSubviews.push filterExpressionSubview
        @renderFilterExpressionSubview filterExpressionSubview, true

    getDefaultFilterExpression: ->
      ['Form', 'transcription', 'like', '%']

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
      else
        @filterExpression = [boolean, [@filterExpression]]
        @$el.fadeOut
          complete: =>
            for subview in @filterExpressionSubviews
              subview.close()
            @initializeFilterExpressionSubviews()
            @$el.empty()
            @render()
            @$el.fadeIn()

    # Change the operator of this filter expression to 'and'.
    makeOperatorAnd: (event) ->
      @stopEvent event
      @makeOperatorBoolean 'and'

    # Change the operator of this filter expression to 'or'.
    makeOperatorOr: (event) ->
      @stopEvent event
      @makeOperatorBoolean 'or'

    # Change the operator of this filter expression to 'not'.
    makeOperatorNot: (event) ->
      @stopEvent event
      @hideActionWidgetAnimate()
      @filterExpression = ['not', @filterExpression]
      @$el.fadeOut
        complete: =>
          for subview in @filterExpressionSubviews
            subview.close()
          @initializeFilterExpressionSubviews()
          @$el.empty()
          @render()
          @$el.fadeIn()

    # TODO: delete this? is this button ever being used?
    emptyOperator: (event) ->
      @hideActionWidgetAnimate()
      @stopEvent event

    # Destroy this filter expression. Note: we trigger a `destroyMe` event and
    # let the parent `FilterExpression` view handle most of the destruction.
    destroyFilterExpression: (event) ->
      @stopEvent event
      @hideActionWidgetAnimate()
      @$el.fadeOut
        complete: =>
          @trigger 'destroyMe', @

    # Toggle the action widget, i.e., the <div> full of buttons that pops up
    # when you click on an "operator" button.
    toggleActionWidget: (event) ->
      if event then @stopEvent event
      $actionWidgetContainer =
        @$('div.filter-expression-action-widget-container').first()
      if $actionWidgetContainer.is ':visible'
        $actionWidgetContainer.slideUp('fast')
      else
        @consentToHideActionWidget = false
        Backbone.trigger 'filterExpressionsHideActionWidgets'
        $actionWidgetContainer.slideDown('fast')

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
        filterExpression: subFilterExpression
        options: @options
      )

    template: filterExpressionTemplate

    render: ->
      context =
        filterExpression: @filterExpression
        options: @options
        attributes: _.keys(@options.search_search_parameters.search_parameters.attributes)
        subattributes: @subattributes() # TODO: we have to do this ourselves! The OLD should provide it though...
        relations: (r for r in \
          _.keys(@options.search_search_parameters.search_parameters.relations) \
          when r isnt 'regexp' and '_' not in r)
        snake2regular: @utils.snake2regular
      @$el.html @template(context)
      @bordercolorify()
      $filterExpressionTable = @$('.filter-expression-table').first()
      @selectmenuify $filterExpressionTable
      $filterExpressionTable
        .find('textarea').autosize().end()
        .find('button').button().end()
        .find('.dative-tooltip').tooltip()
      @renderFilterExpressionSubviews()
      @hideActionWidget()
      @actionButtonsVisibility()
      @listenToEvents()
      @

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
        $actionWidget.find('button.add-coordinand').show()
      else
        $actionWidget.find('button.add-coordinand').hide()

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

    # TODO: the OLD should be supplying all of this information. We should
    # not have to specify it here.
    subattributes: ->
      collections: [
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
      corpora: [
        'id'
        'UUID'
        'name'
        'description'
        'content'
        'enterer'
        'modifier'
        'form_search'
        'datetime_entered'
        'datetime_modified'
        'tags'
        'files'
      ]
      elicitation_method: [
        'id'
        'name'
        'description'
        'datetime_modified'
      ]
      elicitor: @userAttributes
      enterer: @userAttributes
      files: [
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
      memorizers: @userAttributes
      source: [
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
      speaker: [
        'id'
        'first_name'
        'last_name'
        'dialect'
        'markup_language'
        'page_content'
        'html'
        'datetime_modified'
      ]
      syntactic_category: [
        'id'
        'name'
        'type'
        'description'
        'datetime_modified'
      ]
      tags: [
        'id'
        'name'
        'description'
        'datetime_modified'
      ]
      translations: [
        'id'
        'transcription'
        'grammaticality'
        'form_id'
        'datetime_modified'
      ]
      verifier: @userAttributes

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

    renderFilterExpressionSubviews: ->
      for filterExpressionSubview in @filterExpressionSubviews
        @renderFilterExpressionSubview filterExpressionSubview

    renderFilterExpressionSubview: (filterExpressionSubview, animate=false) ->
      @$('.filter-expression-operand').first()
        .append filterExpressionSubview.render().el
      if animate
        filterExpressionSubview.$el
          .hide().fadeIn()
      @rendered filterExpressionSubview

    # Make the border colors match the jQueryUI theme.
    bordercolorify: ->
      @$('.filter-expression-table').first().find('textarea, input')
        .css "border-color", @constructor.jQueryUIColors().defBo
      @$('.filter-expression-action-widget').first()
        .css
          "border-color": @constructor.jQueryUIColors().defBo
          "background-color": @constructor.jQueryUIColors().defCo

