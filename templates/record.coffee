exports.template = ->
  text @root.render current_user: @current_user, is_root: true

  if @current_user
    div id: @current_user, style: "display: none", 'data-id': @current_user._id, 'data-username': @current_user.username
