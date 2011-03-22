exports.template = ->
  text @parent.render "default", is_root: true, current_user: @current_user

  form action: @parent.comment_url(), method: "POST", ->
    textarea name: "comment"
    br()
    input type: "submit", value: "add comment"

exports.sass = """
  .record
    :margin-bottom 10px
    :padding-left 10px
"""
