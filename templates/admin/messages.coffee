exports.template = ->
  p "Send an email"

  form action: "/admin/messages", method: "POST", ->
    input id: "from", type: "text", name: "from", 'data-default-text': "from", value: "jae@ycatalyst.com"
    br()
    input id: "to", type: "text", name: "to", 'data-default-text': "to"
    br()
    input id: "subject", type: "text", name: "subject", 'data-default-text': "subject"
    br()
    textarea id: "body", name: "body", cols: 60, rows: 20, 'data-default-text': "body"
    br()
    input type: "submit", value: "send"

exports.coffeescript = """
  $(document).ready ->
    $('[data-default-text]').set_default_text()
    $('#body').make_autoresizable()
"""
