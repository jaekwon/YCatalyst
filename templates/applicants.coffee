exports.template = ->
  p "Recent applicants:"
  text "TODO show some voting functionality here."
  
  ol class: "applicants", ->
    @applicants.forEach (applicant) ->
      li ->
        div class: 'applicant', 'data-application-id': applicant._id, ->
          span class: 'first_name', -> applicant.first_name
          text " "
          span class: 'last_name', -> applicant.last_name
          if applicant.created_at
            span class: 'applied_at', -> " applied #{applicant.created_at.time_ago()}"
          br()
          if applicant.website
            a href: applicant.website, class: "website", -> applicant.website
            br()
          div class: "comment", ->
            text Markz::markup applicant.comment
    
          # membership voting buttons
          text "vote: "
          a href: "#", title: applicant.accepted_by.join(' '), class: "vote_allow", ->
            text "accept"
            span class: "vote_allow_count", -> applicant.accepted_by
          text " | "
          a href: "#", title: applicant.denied_by.join(' '), class: "vote_deny", ->
            text "deny"
            span class: "vote_allow_count", -> applicant.denied_by
          

exports.sass = """
  body
    .timeago
      :font-size 0.8em
    a.website
      :color #66F
    .first_name, .last_name
      :color #333
    .applied_at
      :font-size 0.8em
    .comment
      :padding 5px
    ol>li>div.applicant
      :margin-bottom 20px
    .vote_allow, .vote_allow:visited
      :color green
    .vote_deny, .vote_deny:visited
      :color red
"""

exports.coffeescript = """
  $(document).ready ->
    $('#vote_allow').live 'click', (event) ->
      alert "OH YOU CLICKED IT!!!"
"""
