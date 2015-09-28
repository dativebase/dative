define [
  './resource-as-row'
], (ResourceAsRowView) ->

  # User as Row View
  # ----------------
  #
  # A view for displaying a user model as a row of cells, one cell per
  # attribute.
  #
  # Note that we only display the values for first and last names, role and id
  # because we are assuming that the users we are displaying are based on the
  # truncated data that are sent by an OLD web service on an /edit request.

  class UserAsRowView extends ResourceAsRowView

    resourceName: 'user'

    orderedAttributes: [
      'first_name'
      'last_name'
      'role'
      'id'
    ]

