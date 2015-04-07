define [
  './resources'
  './../models/subcorpus'
], (ResourcesCollection, SubcorpusModel) ->

  # Subcorpora Collection
  # -----------------------
  #
  # Holds models for subcorpora.

  class SubcorporaCollection extends ResourcesCollection

    resourceName: 'subcorpus'
    model: SubcorpusModel

    # When requesting from the OLD, we need to request 'corpora', not
    # 'subcorpora', hence this attribute.
    serverSideResourceName: 'corpora'

