define [
    'backbone',
    './../models/corpus'
  ], (Backbone, CorpusModel) ->

  # Corpora Collection
  # ------------------
  #
  # Holds models for FieldDB corpora.

  class CorporaCollection extends Backbone.Collection

    model: CorpusModel

