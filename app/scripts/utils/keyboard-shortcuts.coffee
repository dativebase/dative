define [], ->

  # Application-wide keyboard shortcuts are defined here. `MainMenuView` uses
  # this array of objects in its `keyboardShortcuts` method.
  #
  # Note: many of these are arbitrary and are just a convenience during
  # development. It may be a good idea to remove some of these shortcuts and/or
  # make the shortcuts completely user-configurable.

  [
    shortcut: 'ctrl+,'
    event: 'request:applicationSettingsBrowse'
  ,
    shortcut: 'ctrl+h'
    event: 'request:home'
  ,
    shortcut: 'ctrl+p'
    event: 'request:pagesBrowse'
  ,
    shortcut: 'ctrl+c'
    old:
      event: 'request:subcorporaBrowse'
    fielddb:
      event: 'request:corporaBrowse'
  ,
    shortcut: 'ctrl+r'
    event: 'request:openRegisterDialogBox'
  ,
    shortcut: 'ctrl+a'
    event: 'request:formAdd'
  ,
    shortcut: 'ctrl+s'
    event: 'request:searchesBrowse'
  ,
    shortcut: 'ctrl+b'
    event: 'request:formsBrowse'
  ,
    shortcut: 'ctrl+x'
    event: 'request:phonologiesBrowse'
  ,
    shortcut: 'ctrl+m'
    event: 'request:morphologiesBrowse'
  ,
    shortcut: 'ctrl+z'
    event: 'request:languageModelsBrowse'
  ,
    shortcut: 'ctrl+y'
    event: 'request:morphologicalParsersBrowse'
  ,
    shortcut: 'ctrl+?'
    event: 'request:toggleHelpDialogBox'
  ,
    shortcut: 'ctrl+l'
    event: 'request:openLoginDialogBox'
  ,
    shortcut: 'ctrl+t'
    event: 'request:toggleTasksDialog'
  ,
    shortcut: 'ctrl+u'
    event: 'request:usersBrowse'
  ,
    shortcut: 'ctrl+e'
    event: 'request:elicitationMethodsBrowse'
  ,
    shortcut: 'ctrl+g'
    event: 'request:tagsBrowse'
  ,
    shortcut: 'ctrl+v'
    event: 'request:syntacticCategoriesBrowse'
  ,
    shortcut: 'ctrl+n'
    event: 'request:languagesBrowse'
  ,
    shortcut: 'ctrl+o'
    event: 'request:orthographiesBrowse'
  ,
    shortcut: 'ctrl+k'
    event: 'request:speakersBrowse'
  ,
    shortcut: 'ctrl+j'
    event: 'request:sourcesBrowse'
  ,
    shortcut: 'ctrl+i'
    event: 'request:collectionsBrowse'
  ,
    shortcut: 'ctrl+f'
    event: 'request:filesBrowse'
  ,
    shortcut: 'ctrl+q'
    event: 'request:formsImport'
  ]

