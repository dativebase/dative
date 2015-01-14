define [
  'jquery',
  'backbone'
], ($, Backbone) ->

  class Workspace extends Backbone.Router

    routes:
      'home': 'home'
      'application-settings': 'applicationSettings'
      'login': 'openLoginDialogBox'
      'register': 'openRegisterDialogBox'
      'corpora': 'corporaBrowse'
      'form-add': 'formAdd'
      'forms-browse': 'formsBrowse'
      'forms-search': 'formsSearch'
      'pages': 'pages'

