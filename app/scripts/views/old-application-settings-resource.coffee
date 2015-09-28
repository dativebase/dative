define [
  './resource'
  './old-application-settings-add-widget'
  './date-field-display'
  './field-display'
  './orthography-field-display'
  './unicode-string-field-display'
  './array-of-related-users-field-display'
  './../utils/globals'
], (ResourceView, OLDApplicationSettingsAddWidgetView, DateFieldDisplayView,
  FieldDisplayView, OrthographyFieldDisplayView, UnicodeStringFieldDisplayView,
  ArrayOfRelatedUsersFieldDisplay, globals) ->

  class MyArrayOfRelatedUsersFieldDisplay extends ArrayOfRelatedUsersFieldDisplay

    attributeName: 'unrestricted_users'


  class MyUnicodeStringFieldDisplayView extends UnicodeStringFieldDisplayView

    shouldBeHidden: -> false


  class AlwaysVisibleFieldDisplayView extends FieldDisplayView

    shouldBeHidden: -> false


  class StorageOrthographyFieldDisplayView extends OrthographyFieldDisplayView

    shouldBeHidden: -> false


  class InputOrthographyFieldDisplayView extends OrthographyFieldDisplayView

    shouldBeHidden: -> false
    attributeName: 'input_orthography'


  class OutputOrthographyFieldDisplayView extends OrthographyFieldDisplayView

    shouldBeHidden: -> false
    attributeName: 'output_orthography'


  class LanguageCodeFieldDisplayView extends AlwaysVisibleFieldDisplayView

    # https://www.ethnologue.com/language/bla
    getContext: ->
      context = super
      context.valueFormatter = (value) ->
        "<a
          href='https://www.ethnologue.com/language/#{value}'
          target='_blank'
          class='dative-tooltip field-display-link'
          title='Click to view the Ethnologue page for this language id'
          >#{value}</a>"
      context

  class PunctuationFieldDisplayView extends MyUnicodeStringFieldDisplayView

    # We alter `context` so that `context.valueFormatter` is a function that
    # returns an inventory as a list of links that, on mouseover, indicate the
    # Unicode code point and Unicode name of the characters in the graph.
    getContext: ->
      context = super
      context.valueFormatter = (value) =>
        result = []
        graphs = (g.trim() for g in value.split(''))
        for graph in graphs
          result.push @unicodeLink(graph)
        result.join ' '
      context

  class InventoryFieldDisplayView extends MyUnicodeStringFieldDisplayView

    # We alter `context` so that `context.valueFormatter` is a function that
    # returns an inventory as a list of links that, on mouseover, indicate the
    # Unicode code point and Unicode name of the characters in the graph.
    getContext: ->
      context = super
      context.valueFormatter = (value) =>
        result = []
        graphs = (g.trim() for g in value.split(','))
        for graph in graphs
          result.push @unicodeLink(graph)
        result.join ', '
      context


  # OLD Application Settings View
  # -----------------------------
  #
  # For displaying individual OLD application settings models/resources.
  #
  # *Note/Important:* an OLD application settings is a special type of
  # resources. These resources shold not be updated (although the OLD *does*,
  # technically allow that.) Instead, an update should really (though
  # unbeknownst to the user) involve creation of a new application settings
  # object based on the current one. The current application settings is the
  # most recently created one. Application settings should be neither updated
  # nor deleted. This way, past state is always saved.
  #
  # Also, only users with the `administrator` role are permitted to create a
  # new application settings (or update or delete one, even though these
  # actions should not be executed by any user.)

  class OLDApplicationSettingsResourceView extends ResourceView

    resourceName: 'oldApplicationSettings'
    serverSideResourceName: 'applicationsettings'
    resourceAddWidgetView: OLDApplicationSettingsAddWidgetView

    initialize: (options) ->
      options.dataLabelsVisible = true
      options.expanded = true
      super options

    # Users should not be able to delete or duplicate an OLD application
    # settings resource.
    excludedActions: [
      'history'  # forms have this, since everything is version controlled.
      'controls' # phonologies have this, for, e.g., phonologizing.
      'data'     # file resources have this, for accessing their file data.
      'delete'
      'duplicate'
    ]

    mainPageViewable: -> false

    # Attributes that are always displayed.
    primaryAttributes: [
      'object_language_name'
      'object_language_id'
      'metalanguage_name'
      'metalanguage_id'
      'metalanguage_inventory'
      'orthographic_validation'
      'narrow_phonetic_inventory'
      'narrow_phonetic_validation'
      'broad_phonetic_inventory'
      'broad_phonetic_validation'
      'morpheme_break_is_orthographic'
      'morpheme_break_validation'
      'phonemic_inventory'
      'morpheme_delimiters'
      'punctuation'
      'grammaticalities'
      'storage_orthography'
      'input_orthography'
      'output_orthography'
      'datetime_modified'
      'unrestricted_users'
      'id'
    ]

    # Attributes that may be hidden.
    secondaryAttributes: []

    # Map attribute names to display view class names.
    attribute2displayView:
      datetime_modified: DateFieldDisplayView
      storage_orthography: StorageOrthographyFieldDisplayView
      input_orthography: InputOrthographyFieldDisplayView
      output_orthography: OutputOrthographyFieldDisplayView
      object_language_id: LanguageCodeFieldDisplayView
      metalanguage_id: LanguageCodeFieldDisplayView
      metalanguage_inventory: InventoryFieldDisplayView
      narrow_phonetic_inventory: InventoryFieldDisplayView
      broad_phonetic_inventory: InventoryFieldDisplayView
      phonemic_inventory: InventoryFieldDisplayView
      morpheme_delimiters: InventoryFieldDisplayView
      grammaticalities: InventoryFieldDisplayView
      punctuation: PunctuationFieldDisplayView
      unrestricted_users: MyArrayOfRelatedUsersFieldDisplay

    getHeaderTitle: ->
      if globals.applicationSettings.get 'loggedIn'
        activeServer = globals.applicationSettings.get 'activeServer'
        activeServerName = activeServer.get 'name'
      else
        activeServerName = null
      if @model.get 'object_language_name'
        name = @model.get 'object_language_name'
        if activeServerName
          "Settings for the OLD server “#{activeServerName}” for the
            language #{name}"
        else
          "Settings for the OLD server for the language #{name}"
      else
        "Settings for an OLD server"
        if activeServerName
          "Settings for the OLD server “#{activeServerName}”"
        else
          'Settings for an OLD server'

    # Return the appropriate DisplayView (subclass) instance for a given
    # attribute, as specified in `@attribute2displayView`. The default display
    # view is `FieldDisplayView`.
    getDisplayView: (attribute) ->
      if attribute of @attribute2displayView
        MyDisplayView = @attribute2displayView[attribute]
        new MyDisplayView(@getDisplayViewParams(attribute))
      else # the default display view is AlwaysVisibleFieldDisplayView
        new AlwaysVisibleFieldDisplayView(@getDisplayViewParams(attribute))

    addSuccess: ->
      @indicateModelIsUnaltered()
      @refreshTooltips()

    listenToEvents: ->
      super
      @listenTo @model, 'addOldApplicationSettingsSuccess', @addSuccess

    focusFirstUpdateViewField: ->
      x = => @$('.update-resource-widget textarea').first().focus()
      setTimeout x, 1000

