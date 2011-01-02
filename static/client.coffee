if not window.app?
  window.app = {}
app = window.app

# get the id of the current user
app.current_user = "XXX"

# list of all newly upvoted records
app.upvoted = []

# show a dialog with some challenge on it
app.upvote = (rid) ->
  app.upvoted.push(rid)
  $.ajax {
    cache: false
    type: "POST"
    url: "/r/#{rid}/upvote"
    dataType: "json"
    error: ->
      console.log('meh')
    success: (data) ->
      # updating the new record happens 
      # with longpolling below.
  }

# show reply form inline with the record
app.show_reply_box = (rid) ->
  app.Record::show_reply_box rid

# post the reply
app.post_reply = (rid) ->
  alert(rid)

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
      setTimeout(( -> app.poll(root)), 10*1000)
    success: (data) ->
      try
        app.poll_errors = 0
        if data
          for recdata in data
            # if we need to insert a new record
            if $('#'+recdata.parent_id).length > 0 and $('#'+recdata._id).length == 0
              # insert!
              parent = $('#'+recdata.parent_id)
              record = new window.app.Record(recdata)
              parent.find('.children:eq(0)').prepend(record.render(is_root: false))
            # otherwise we're updating possibly an existing record
            else
              hide_upvote = app.upvoted.indexOf(recdata._id) != -1
              record = new window.app.Record(recdata)
              record.redraw(hide_upvote: hide_upvote)
          app.poll(root)
        else
          # might be a broken connection.
          # ajax requests should at least come back with a {status}
          app.poll_errors += 1
          setTimeout(( -> app.poll(root)), 10*1000)
      catch e
        console.log(e)
  }

# set up autoresize forms.
app.make_autoresizable = (textarea) ->
  cloned_textarea = textarea.clone()
  cloned_textarea.css
    minHeight: textarea.css('min-height')
    minWidth: textarea.css('min-width')
    fontFamily: textarea.css('font-family')
    fontSize: textarea.css('font-size')
    padding: textarea.css('padding')
    overflow: 'hidden' # the cloned textarea's scrollbar causes an extra newline at the end sometimes
  # hide it but don't actually hide it. 
  cloned_textarea.css position: 'absolute', left: '-1000000px', disabled: true
  $(document.body).prepend cloned_textarea
  autoresize = (event) ->
    cloned_textarea.val textarea.val()
    textarea.css 'height', cloned_textarea[0].scrollHeight
  textarea.bind('keyup', autoresize)

$(document).ready ->
  # start longpoll'n
  if $('[data-root="true"]').length > 0
    root = $('[data-root="true"]:eq(0)')
    # http://stackoverflow.com/questions/2703861/chromes-loading-indicator-keeps-spinning-during-xmlhttprequest
    setTimeout(( -> app.poll(root)), 500)

