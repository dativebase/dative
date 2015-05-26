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
  # accepts.

  class FilterExpressionView extends BaseView

    initialize: (options) ->
      @filterExpression = options.filterExpression
      @options = options.options
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
        relations: _.keys(@options.search_search_parameters.search_parameters.relations)
        snake2regular: @utils.snake2regular
      @$el.html @template(context)
      @$('.filter-expression-table').first().find('select').selectmenu width: 'auto'
      @bordercolorify()
      @$('.filter-expression-table').first().find('textarea').autosize()
      @renderFilterExpressionSubviews()
      @

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
        @$('.filter-expression-operand').first().append filterExpressionSubview.render().el
        @rendered filterExpressionSubview

    # Make the border colors match the jQueryUI theme.
    bordercolorify: ->
      @$('.filter-expression-table').first().find('textarea, input')
        .css "border-color", @constructor.jQueryUIColors().defBo

