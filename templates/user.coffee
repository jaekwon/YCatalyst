exports.template = ->
  table ->
    tr ->
      td ->
        label "user"
      td ->
        text @user.username
    tr ->
      td ->
        label "joined"
      td ->
        text @user.created_at.time_ago()
    tr ->
      td valign: "top", ->
        label "bio"
      td ->
        if @is_self
          # looking at your own bio
          form action: "/user/"+@user.username, method: "POST", ->
            textarea id: "bio", name: "bio", -> @user.bio or ''
            br()
            input type: "submit", value: "update"
        else
          # looking at someone else's bio
          if @user.bio
            text Markz::markup @user.bio
          else
            i "no bio"
        
exports.coffeescript = ->
  $(document).ready ->
    $('#bio').make_autoresizable()
