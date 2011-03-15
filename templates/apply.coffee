exports.template = ->
  p "YCatalyst Application"
  p "Membership requires screening by existing members. Please fill out the form below."
  
  form action: "/apply", method: "POST", ->
    if typeof application != 'undefined'
      input type: "hidden", name: "application_id", value: @application._id
      @referral = {}
    else
      @application = {}
    input type: "hidden", name: "referral_id", value: @referral._id
    input id: "first_name", type: "text", name: "first_name", 'data-default-text': "first name", value: @referral.first_name or @application.first_name or ''
    br()
    input id: "last_name", type: "text", name: "last_name", 'data-default-text': "last name", value: @referral.last_name or @application.last_name or ''
    br()
    input id: "email", type: "text", name: "email", 'data-default-text': "email", value: @referral.email or @application.email or ''
    br()
    input id: "website", type: "text", name: "website", 'data-default-text': "website"
    br()
    p "Please explain why you should be granted membership in the field below."
    textarea id: "comment", name: "comment", cols: 60, rows: 20, -> @application.comment or ''
    br()
    input type: "submit", value: "apply"

exports.sass = """
  #first_name, #last_name, #email
    :width 200px
"""

exports.coffeescript = ->
  $(document).ready ->
    $('input[data-default-text]').set_default_text()
    $('#comment').make_autoresizable()
