exports.template = ->
  if @type == 'link'
    form action: "/submit", method: "POST", ->
      table ->
        tr ->
          th ->
            span "title"
          td ->
            input type: "text", name: "title", value: @link_title or ''
          td ->
            i style: "color: gray", -> "required"
        tr ->
          td colspan: 3, ->
            br()
        tr ->
          th ->
            span "url"
          td ->
            input type: "text", name: "url", value: @link_url or ''
        tr ->
          th()
          td ->
            span style: "font-weight: bold; color: gray", -> "and/or"
        tr ->
          th valign: "top", ->
            span "text"
          td ->
            textarea name: "text"
        tr ->
          th()
          td ->
            input type: "submit", value: "submit"
  else if @type == 'poll'
    form action: "/submit", method: "POST", ->
      input type: "hidden", name: "type", value: "poll", ->
      table ->
        tr ->
          th ->
            span "title"
          td ->
            input type: "text", name: "title", value: "Poll: ", ->
          td ->
            i style: "color: gray", -> "required"
        tr ->
          th valign: "top", ->
            span "text"
          td ->
            textarea name: "text"
        tr ->
          th()
          td ->
            span "Use blank lines to seperate choices"
        tr ->
          th valign: "top", ->
            span "choices"
          td ->
            textarea name: "choices"
        tr ->
          th()
          td ->
            input type: "submit", value: "submit"

  p ->
    text "Or, submit via "
    a href: "/bookmarklet", -> "bookmarklet"

exports.coffeescript = ->
  $(document).ready ->
    $('textarea').make_autoresizable()
