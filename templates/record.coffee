exports.template = ->
  text @root.render current_user: @current_user, is_root: true, heading_title: true

# root, or is_root, means that the item is at root level in the DOM.
# when you visit a record using the 'link' URL, it becomes 'root'.
exports.sass = """
  .record[data-root="true"]
    &>.contents
      :margin 10px 0px
    &>.item_info
      :font-size 7pt
"""

exports.coffeescript = ->
  App.start_longpolling()
