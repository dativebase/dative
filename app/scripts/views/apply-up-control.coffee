define ['./apply-control'], (ApplyControlView) ->

  # Apply Up Control View
  # ---------------------
  #
  # For allowing the user to call "apply up" against an FST-based resource.

  class ApplyUpControlView extends ApplyControlView

    direction: 'up'

