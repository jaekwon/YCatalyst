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
          a href: "#", title: applicant.accepted_by.join(' '), class: "vote_accept", ->
            text "accept"
            span class: "vote_accept_count", -> applicant.accepted_by.length
          text " | "
          a href: "#", title: applicant.denied_by.join(' '), class: "vote_deny", ->
            text "deny"
            span class: "vote_deny_count", -> applicant.denied_by.length
          

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
    .vote_accept, .vote_accept:visited
      :color green
    .vote_deny, .vote_deny:visited
      :color red
"""

exports.coffeescript = ->
  $(document).ready ->
    # vote up or down.
    # vote_type: 'accept' or 'deny'
    vote = (element, vote_type) ->
      $.ajax
        cache: false
        type: "POST"
        url: "/applicants/#{element.attr('data-applicaiton-id')}/vote"
        data: {vote: vote_type}
        dataType: "json"
        error: ->
          alert "Error, please refresh and try again later."
        success: (data) ->
          switch vote_type
            when 'accept'
              element.find('.vote_accept').addClass('chosen')
              element.find('.vote_accept_count').increment()
              element.find('.vote_deny').removeClass('chosen')
              element.find('.vote_deny_count').decrement()
            when 'deny'
              element.find('.vote_deny').addClass('chosen')
              element.find('.vote_deny_count').increment()
              element.find('.vote_accept').removeClass('chosen')
              element.find('.vote_accept_count').decrement()
    # bind events 
    $('.vote_accept').live 'click', (event) ->
      vote($(this).parents('.applicant:eq(0)'), 'accept')
    $('.vote_deny').live 'click', (event) ->
      vote($(this).parents('.applicant:eq(0)'), 'deny')
