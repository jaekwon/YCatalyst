if not window.app?
  window.app = {}
app = window.app

# gets set at document.ready
app.current_user = null

# depth of comments to show
app.DEFAULT_DEPTH = 5

# list of all newly upvoted records
app.upvoted = null

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
            parent = $('#'+recdata.parent_id)
            # if we need to insert a new record
            if $('#'+recdata.parent_id).length > 0 and $('#'+recdata._id).length == 0
              # insert if parent is not a leaf node
              if parent.parents('.record').length >= app.DEFAULT_DEPTH
                # this is too far. skip it.
                # instead, the parent should be in the data as well 
                # and that, updated w/ is_root option, should display 
                # the new number of children
              else
                # render it
                record = new window.app.Record(recdata)
                parent.find('.children:eq(0)').prepend(record.render(is_root: false, current_user: app.current_user))
            # otherwise we're updating possibly an existing record
            else
              is_leaf = parent.parents('.record').length >= (app.DEFAULT_DEPTH-1)
              record = new window.app.Record(recdata)
              record.redraw(is_leaf: is_leaf, current_user: app.current_user)
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
  # we don't use a textarea because chrome has issues with undo's not working
  # when you interlace edits on multiple textareas.
  cloned_textarea = $(document.createElement('div')); #textarea.clone()
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
    cloned_textarea.css
      width: textarea.css('width')
    #console.log(textarea.css('height'))
    cloned_textarea.text('')
    for line in textarea.val().split("\n")
      cloned_textarea.append(hE(line))
      cloned_textarea.append('<br/>')
    cloned_textarea.append('<br/>')
    textarea.css 'height', cloned_textarea[0].scrollHeight
  textarea.bind('keyup', autoresize)
  # force autoresize right now
  setTimeout(autoresize, 0)

$(document).ready ->
  # get the id of the current user
  app.current_user =
    if $('#current_user').length > 0
      _id: $("#current_user").attr('data-id'), username: $("#current_user").attr('data-username')
    else
      null

  # start longpoll'n
  if $('[data-root="true"]').length > 0
    root = $('[data-root="true"]:eq(0)')
    # http://stackoverflow.com/questions/2703861/chromes-loading-indicator-keeps-spinning-during-xmlhttprequest
    setTimeout(( -> app.poll(root)), 500)

  # find all upvoted records
  app.upvoted = $.map($('.record[data-upvoted="true"]'), (e) -> e.id)
