###
# YCatalyst
# Copyright(c) 2011 Jae Kwon (jae@ycatalyst.com)
# MIT Licensed
###

App = window.App = {}

# most pages are real time, but the inbox is not.
# this flag determines whether to update records
# from the synchronous response data, or from longpolling.
App.is_longpolling = false

# gets set at document.ready
App.current_user = null

# depth of comments to show
App.DEFAULT_DEPTH = 5

# list of all newly upvoted records
App.upvoted = null
App.following = null

# include a javascript file TODO support jsonp
App.include = (filename) ->
  script = document.createElement('script')
  script.src = filename
  script.type = 'text/javascript'
  $('head').append(script)

# counter to prevent server flooding
App.poll_errors = 0

# insert/render or redraw the records based on new/updated recdata from the server
App.handle_updates = (recdatas) ->
  for recdata in recdatas
    parent = $('#'+recdata.parent_id)
    # if we need to insert a new record
    if $('#'+recdata.parent_id).length > 0 and $('#'+recdata._id).length == 0
      # insert if parent is not a leaf node
      if parent.parents('.record').length >= App.DEFAULT_DEPTH
        # this is too far. just increment 'xyz more replies' of the parent.
        parent.find('>.children>.more').removeClass('hidden').find('>.number').increment()
      else
        # render it
        record = new Record(recdata)
        if record.recdata.type == 'choice'
          parent.find('>.contents>.choices').append(record.render("default", is_root: false, current_user: App.current_user))
        else
          parent.find('>.children').prepend(record.render("default", is_root: false, current_user: App.current_user))
    # otherwise we're updating possibly an existing record
    else
      record = new Record(recdata)
      record.redraw(current_user: App.current_user)

# poll for updates for root and its near children
App.poll = (root) ->
  $.ajax {
    cache: false
    type: "GET"
    url: "/r/#{root.attr('id')}/recv"
    dataType: "json"
    error: ->
      App.poll_errors += 1
      console.log "polling again in 10: error"
      setTimeout(( -> App.poll(root)), 10*1000)
    success: (data) ->
      try
        App.poll_errors = 0
        if data
          App.handle_updates data
          console.log "polling again immediately"
          App.poll(root)
        else
          # might be a broken connection.
          # ajax requests should at least come back with a {status}
          App.poll_errors += 1
          console.log "polling again in 10: error?"
          setTimeout(( -> App.poll(root)), 10*1000)
      catch e
        console.log(e)
  }

# given an input field or textarea, 
# show some default text (gray, italicized)
# input: a single jQuery selection
# default_text: (optional) the default text to show
#  if not present, will look for 'data-default-text' html attribute
App.set_default_text = (input, default_text) ->
  orig_name = input.attr('name')
  default_text ||= input.attr('data-default-text')
  on_focus = =>
    input.removeClass 'default_text'
    input.attr('name', orig_name) # to handle synchronous submits
    if input.val() == default_text
      input.val ''
  on_blur = =>
    if input.val() == default_text or input.val() == ''
      input.val(default_text)
      input.attr('name', '_not_'+orig_name) # to handle synchronous submits
      input.addClass 'default_text'
  on_blur()
  input.focus(on_focus)
  input.blur(on_blur)
  input.data('default_text', default_text)

jQuery.fn.extend(
  'set_default_text': (default_text) ->
    this.each (i, thor) ->
      elem = $(thor)
      App.set_default_text(elem, default_text)
  'get_value': () ->
    value = $(this).val()
    if $(this).data('default_text') == value
      return ''
    else
      return value
  'increment': () ->
    this.text(parseInt(this.text())+1)
  'decrement': () ->
    this.text(parseInt(this.text())-1)
  'make_autoresizable': () ->
    this.each (i, textarea) ->
      textarea = $(textarea)
      # we don't use a textarea because chrome has issues with undo's not working
      # when you interlace edits on multiple textareas.
      cloned_textarea = $(document.createElement('div')); #textarea.clone()
      cloned_textarea.attr
        cols: textarea.attr('cols')
        rows: textarea.attr('rows')
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
)

# start longpoll'n
App.start_longpolling = ->
  App.is_longpolling = true
  if $('[data-root="true"]').length > 0
    root = $('[data-root="true"]:eq(0)')
    # http://stackoverflow.com/questions/2703861/chromes-loading-indicator-keeps-spinning-during-xmlhttprequest
    setTimeout(( -> App.poll(root)), 500)

$(document).ready ->
  # get the id of the current user
  App.current_user =
    if $('#current_user').length > 0
      _id: $("#current_user").attr('data-id'), username: $("#current_user").attr('data-username')
    else
      null
  # find all upvoted records
  App.upvoted = $.map($('.record[data-upvoted="true"]'), (e) -> e.id)
  # find all following records
  App.following = $.map($('.record[data-following="true"]'), (e) -> e.id)
