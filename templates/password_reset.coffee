exports.template = ->
  if typeof @user == 'undefined'
    p "Enter your email address and we'll send you a password reset link."

    form action: "/password_reset", method: 'POST', ->
      table ->
        tr ->
          td ->
            label "email"
          td ->
            input name: "email"
        tr ->
          td colspan: 2, ->
            input type: "submit", value: "reset"
  else
    p "Enter your new desired password"

    form action: "/password_reset", method: "POST", ->
      input type: "hidden", name: "username", value: @user.username
      input type: "hidden", name: "password_reset_nonce", value: @user.password_reset_nonce
      table ->
        tr ->
          td ->
            label "password"
          td ->
            input name: "password", type: "password"
        tr ->
          td ->
            label "password repeat"
          td ->
            input name: "password2", type: "password"
        tr ->
          td colspan: 2, ->
            input type: "submit", value: "reset"
