if not window.app?
  window.app = {}
app = window.app

# get the id of the current user
app.current_user = "XXX"

# show a dialog with some challenge on it
app.upvote = (rid) ->
  $.ajax {
    cache: false
    type: "POST"
    url: "/r/#{rid}/upvote"
    dataType: "json"
    error: ->
      console.log('meh')
    success: (data) ->
      # update the new record
      record = new window.app.Record(data.recdata)
      record.redraw()
  }

# include a javascript file TODO support jsonp
app.include = (filename) ->
  script = document.createElement('script')
  script.src = filename
  script.type = 'text/javascript'
  $('head').append(script)

# counter to prevent server flooding
app.poll_errors = 0

# poll for updates for root and its near children
app.poll = (root) ->
  $.ajax {
    cache: false
    type: "GET"
    url: "/r/#{root.attr('id')}/recv"
    dataType: "json"
    error: ->
      app.poll_errors += 1
      setTimeout(app.poll, 10*1000)
    success: (data) ->
      try
        app.poll_errors = 0
        if data
          for recdata in data
            if $('#'+recdata.parent_id).length > 0 and $('#'+recdata._id).length == 0
              # insert!
              parent = $('#'+recdata.parent_id)
              record = new window.app.Record(recdata)
              parent.find('.children:eq(0)').prepend(record.render(is_root: false))
        app.poll(root)
      catch e
        console.log(e)
  }

$(document).ready ->
  # start longpoll'n
  if $('[data-root="true"]').length > 0
    root = $('[data-root="true"]:eq(0)')
    # http://stackoverflow.com/questions/2703861/chromes-loading-indicator-keeps-spinning-during-xmlhttprequest
    setTimeout(( -> app.poll(root)), 500)
