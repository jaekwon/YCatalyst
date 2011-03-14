exports.template = ->
  text @root.render current_user: @current_user, is_root: true
