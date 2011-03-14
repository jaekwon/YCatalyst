exports.template = ->
  if typeof message != "undefined"
    p message
  else
    p "Login here"

  form action: "/login", method: "POST", ->
    table ->
      tr ->
        td ->
          label "username"
        td ->
          input name: "username"
      tr ->
        td ->
          label "password"
        td ->
          input name: "password", type: "password"
      tr ->
        td colspan: 2, ->
          input type: "submit", value: "login"

  p ->
    text "New user?"
    br()
    text "Please register if you have an invite code. We're in private alpha!"

  form action: "/register", method: "POST", ->
    table ->
      tr ->
        td ->
          label "desired username"
        td ->
          input name: "username"
      tr ->
        td ->
          label "desired password"
        td ->
          input name: "password", type: "password"
      tr ->
        td ->
          label "password repeat"
        td ->
          input name: "password2", type: "password"
      tr ->
        td ->
          label "email"
        td ->
          input name: "email"
      tr ->
        td ->
          label "invite code"
        td ->
          input name: "invite"
      tr ->
        td colspan: 2, ->
          input type: "submit", value: "register"

  p ->
    text "Forgot your password? "
    a href: "/password_reset", ->
      "Reset it!"

