exports.template = ->
  doctype 5
  html ->
    head ->
      title @title
      script type: "text/javascript", src: "https://www.google.com/jsapi?key=ABQIAAAAV88HHyf8NBcAL3aio53OixSEBwhbzDd0F998UkbSll3boCkrihTFj2uO3yETr_J5z25r2aIc4YCVpQ"
      #script type: "text/javascript", src: "https://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js"
      for file in ["jquery-1.4.2.min.js", "underscore.js", "client.js", "coffeekup.js", "markz.js", "record.js"]
        script type: "text/javascript", src: static_file(file)
      link type: "text/css", rel: "stylesheet", href: static_file("main.css")

    body ->
      div id: "headerbar", ->
        if typeof @headerbar_text != "undefined"
          span class: "logo", -> @headerbar_text
        else
          a class: "logo", href: "/", ->
            img src: "/static/logo.png"
        span class: "links", ->
          a href: "/submit", -> "submit"
          text " | "
          a href: "/submit?type=poll", -> "poll"
        div style: "float: right", ->
          if @current_user
            a href: "/refer", -> "refer a friend"
            text " | "
            a href: "/user/#{@current_user.username}", class: "username", -> @current_user.username
            text " | "
            a href: "/logout", class: "logout", -> "logout"
          else
            a href: "/apply", -> "apply"
            text " | "
            span class: "username", -> "anonymous"
            text " | "
            a href: "/login", class: "login", -> "login"
      
      div id: "body_contents", ->
        text render(@body_template, @body_context)

      if @current_user
        div id: 'current_user', style: "display: none", 'data-id': @current_user._id, 'data-username': @current_user.username
