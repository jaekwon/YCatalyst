exports.template = ->
  ol class: "users", ->
    @users.forEach (user) ->
      li ->
        div class: "user", ->
          a href: '/user/'+user.username, class: 'username', -> user.username
          text " "
          span class: 'timeago', -> "joined #{user.created_at.time_ago()}"

exports.sass = """
  .timeago
    :font-size 0.8em
"""
