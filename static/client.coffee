include = (filename) ->
  script = document.createElement('script')
  script.src = filename
  script.type = 'text/javascript'
  $(document.head).append(script)

poll_errors = 0 # counter to prevent server flooding

# poll for updates for root and its near children
poll = (root) ->
  $.ajax {
    cache: false,
    type: "GET",
    url: "/r/#{root.attr('id')}/recv",
    dataType: "json",
    error: ->
      poll_errors += 1
      setTimeout(poll, 10*1000)
    success: (data) ->
      try
        poll_errors = 0
        if data
          for recdata in data
            if $('#'+recdata.parent_id).length > 0 and $('#'+recdata._id).length == 0
              # insert!
              parent = $('#'+recdata.parent_id)
              record = new window.app.Record(recdata)
              parent.find('.children:eq(0)').prepend(record.render(is_root: false))
        poll(root)
      catch e
        console.log(e)
  }

$(document).ready ->
  # include record.js
  # TODO need to use jsonp or something
  include "/static/record.js"
  
  # start longpoll'n
  if $('[data-root="true"]').length > 0
    root = $('[data-root="true"]:eq(0)')
    # http://stackoverflow.com/questions/2703861/chromes-loading-indicator-keeps-spinning-during-xmlhttprequest
    setTimeout(( -> poll(root)), 500)
