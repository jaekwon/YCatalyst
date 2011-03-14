exports.template = ->
  p ->
    text """
      Use this form to refer somebody you know into the network.
      The referred person still needs to fill out an application.
    """
    br()
    text " You can view and vote on applicants "
    a href: "/applicants", -> "here"

  form action: "/refer", method: "POST", ->
    input id: "first_name", type: "text", name: "first_name"
    br()
    input id: "last_name", type: "text", name: "last_name"
    br()
    input id: "email", type: "text", name: "email"
    br()
    input type: "submit", value: "submit"

exports.sass = """
  #first_name, #last_name, #email
    :width 200px
"""

exports.coffeescript = """
  $(document).ready ->
    $('#first_name').set_default_text 'first name'
    $('#last_name').set_default_text 'last name'
    $('#email').set_default_text 'email'
"""
