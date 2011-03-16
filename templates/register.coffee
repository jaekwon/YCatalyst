exports.template = ->
  if @invite_code
    p "Please register here."
  else
    p "Please register here if you have an invite code."

  form action: "/register", method: "POST", ->
    input id: "username", type: "text", name: "username", 'data-default-text': "desired username"
    br()
    input id: "password", type: "password", name: "password", 'data-default-text': "****"
    label " password"
    br()
    input id: "password2", type: "password", name: "password2", 'data-default-text': "****"
    label " password repeat"
    br()
    input id: "email", type: "text", name: "email", 'data-default-text': "email", value: @email or ''
    br()
    input id: "invite", type: "text", name: "invite", 'data-default-text': "invite code", value: @invite_code or ''
    br()
    input type: "submit", value: "register"

exports.sass = """
  #username, #password, #password2, #email, #invite
    :width 200px
"""

exports.coffeescript = ->
  $(document).ready ->
    $('input[data-default-text]').set_default_text()
