define [
  './resources'
  './subcorpus'
  './../collections/subcorpora'
  './../models/subcorpus'
], (ResourcesView, SubcorpusView, SubcorporaCollection, SubcorpusModel) ->

  # Subcorpora View
  # -----------------
  #
  # Displays a collection of subcorpora for browsing, with pagination. Also
  # contains a model-less SubcorpusView instance for creating new subcorpora
  # within the browse interface.
  #
  # Note: most functionality is coded in the `ResourcesView` base class.

  class SubcorporaView extends ResourcesView

    resourceName: 'subcorpus'
    resourceView: SubcorpusView
    resourcesCollection: SubcorporaCollection
    resourceModel: SubcorpusModel

    initialize: (options) ->
      super options
      @resourceNameHuman = 'corpus'
      @resourceNamePluralHuman = 'corpora'

