define [
  'backbone'
  './../utils/cors'
  './../utils/utils'
  'backbonerelational'
], (Backbone, CORS, utils) ->

  # Base Relational Model
  # ---------------------
  #
  # Functionality that all relational models and collections need.

  class BaseRelationalModel extends Backbone.RelationalModel

    guid: utils.guid
    @cors: new CORS()
    utils: utils

