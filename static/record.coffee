# currently, any time we modify this file we need to ./static/compile and possibly restart the server :(

# we have to rename, otherwise coffeescript declares 'var CoffeeKup' which wipes the client side import
coffeekup = if CoffeeKup? then CoffeeKup else require 'coffeekup'
markz = if Markz? then Markz else require('./markz').Markz
if window?
  if not window.app?
    window.app = {}
  app = window.app
else
  app = require '../app'

# possibly move this out
Date.prototype.time_ago = () ->
  difference = (new Date()) - this
  if difference < 60 * 1000
    return "a moment ago"
  if difference < 60 * 60 * 1000
    return Math.floor((difference/(60*1000))) + " minutes ago"
  if difference < 2 * 60 * 60 * 1000
    return "1 hour ago"
  if difference < 24 * 60 * 60 * 1000
    return Math.floor((difference/(60*60*1000))) + " hours ago"
  if difference < 2 * 24 * 60 * 60 * 1000
    return "1 day ago"
  if difference < 30 * 24 * 60 * 60 * 1000
    return Math.floor((difference/(24*60*60*1000))) + " days ago"
  if difference < 2 * 30 * 24 * 60 * 60 * 1000
    return "1 month ago"
  if difference < 365 * 24 * 60 * 60 * 1000
    return Math.floor((difference/(30*24*60*60*1000))) + " months ago"
  if difference < 2 * 365 * 24 * 60 * 60 * 1000
    return "1 year ago"
  return Math.floor((difference/(365*24*60*60*1000))) + " years ago"

# usage: 
# r = new Record({record_data})
# r.object # {record_data}
# r.render() # <html>
#
# child = Record.create({child_data}, r)
# child.is_new # true
#
# We keep the recdata seperate from the Record, so
# as to not pollute the db fields.
# Probably a better way to handle this with prototypes :/
class Record

  # uses object(recdata) to hydrate a new Record instance.
  # if you want to add a Record to the DB, you want to call
  # logic.records.create_record()
  constructor: (object) ->
    @object = object
    if not @object.points?
      @object.points = 0
    if not @object.num_children?
      @object.num_children = 0
    if not @object.created_at?
      @object.created_at = new Date()
    else if typeof @object.created_at == 'string'
      # after JSON serialization, created_at reverts to string on client
      @object.created_at = new Date(@object.created_at)

  render_kup: ->
    div class: "record", id: @object._id, "data-root": is_root, "data-upvoted": upvoted, ->
      if current_user? and not upvoted
        a class: "upvote", href: '#', onclick: "app.upvote('#{h(@object._id)}'); return false;", -> "&#9650;"
      if @object.title
        if @object.url
          a href: @object.url, class: "title", -> @object.title
          if @object.host
            span class: "host", -> "&nbsp;(#{@object.host})"
        else
          a href: "/r/#{@object._id}", class: "title", -> @object.title
        br foo: "bar"
      span class: "item_info", ->
        span -> " #{@object.points or 0} pts by "
        a href: "/user/#{h(@object.created_by)}", -> h(@object.created_by)
        span -> " " + @object.created_at.time_ago()
        text " | "
        if is_root and @object.parent_id
          a class: "parent", href: "/r/#{@object.parent_id}", -> "parent"
          text " | "
        a class: "link", href: "/r/#{@object._id}", -> "link"
        if current_user? and @object.created_by == current_user.username
          text " | "
          a class: "edit", href: "#", onclick: "app.show_edit_box('#{h(@object._id)}'); return false;", -> "edit"
          text " | "
          a class: "delete", href: "#", onclick: "app.delete('#{h(@object._id)}'); return false;", -> "delete"
      div class: "contents", ->
        text markz::markup(@object.comment) if @object.comment
        text " "
        a class: "reply", href: "/r/#{@object._id}/reply", onclick: "app.show_reply_box('#{h(@object._id)}'); return false;", -> "reply"
        # placeholders
        div class: "edit_box_container"
        div class: "reply_box_container"
      div class: "children", ->
        if @children
          for child in @children
            text child.render(is_root: false, current_user: current_user)
        loaded_children = if @children then @children.length else 0
        if loaded_children < @object.num_children
          a class: "more", href: "/r/#{@object._id}", -> "#{@object.num_children - loaded_children} more replies"

  # options:
  #   is_root -> default true, if false, doesn't show parent_link,
  render: (options) ->
    is_root = not options? or options.is_root
    current_user = options.current_user if options?
    upvoted =
      if window?
        app.upvoted.indexOf(@object._id) != -1
      else if current_user?
        @object.upvoters? and @object.upvoters.indexOf(current_user._id) != -1
    coffeekup.render @render_kup, context: this, locals: {markz: markz, is_root: is_root, upvoted: upvoted, current_user: current_user}, dynamic_locals: true

  render_headline_kup: ->
    div class: "record", id: @object._id, ->
      if current_user? and not upvoted
        a class: "upvote", href: '#', onclick: "app.upvote('#{h(@object._id)}'); $(this).parent().find('>.item_info>.points').increment(); $(this).remove(); return false;", -> "&#9650;"
      if @object.url
        a href: @object.url, class: "title", -> @object.title
        if @object.host
          span class: "host", -> "&nbsp;(#{@object.host})"
      else
        a href: "/r/#{@object._id}", class: "title", -> @object.title
      br foo: "bar"
      span class: "item_info", ->
        span class: "points", -> "#{@object.points or 0}"
        span -> " pts by "
        a href: "/user/#{h(@object.created_by)}", -> h(@object.created_by)
        text " | "
        if @object.num_discussions
          a href: "/r/#{@object._id}", -> "#{@object.num_discussions} comments"
        else
          a href: "/r/#{@object._id}", -> "discuss"

  render_headline: (options) ->
    current_user = options.current_user if options?
    upvoted =
      if window?
        app.upvoted.indexOf(@object._id) != -1
      else if current_user?
        @object.upvoters? and @object.upvoters.indexOf(current_user._id) != -1
    coffeekup.render @render_headline_kup, context: this, locals: {markz: markz, upvoted: upvoted, current_user: current_user}, dynamic_locals: true

  comment_url: ->
    "/r/#{@object._id}/reply"

  # client side #
  # update the record (which already exists in the dom)
  # is_leaf: default false. if true, renders the new num_children
  # current_user: the current user XXX find better way
  redraw: (options) ->
    old = $("\##{@object._id}")
    old_is_root = old.attr('data-root') == "true"
    children = old.find('.children:eq(0)').detach()
    options.is_root = old_is_root
    old.replaceWith(this.render(options))
    if not options? or not options.is_leaf
      $("\##{@object._id}").find('.children:eq(0)').replaceWith(children)

  # client side #
  # static method #
  # show a dialog with some challenge on it
  upvote: (rid) ->
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

  # client side #
  # static method #
  show_reply_box: (rid) ->
    record_e = $('#'+rid)
    window.qwe = record_e
    if record_e.find('>.contents>.reply_box_container>.reply_box').length == 0
      kup = ->
        div class: "reply_box", ->
          textarea name: "comment"
          br foo: 'bar' # dunno why just br doesn't work
          button onclick: "app.post_reply('#{rid}')", -> 'post comment'
          button onclick: "$(this).parent().remove()", -> 'cancel'
      container = record_e.find('>.contents>.reply_box_container').append(coffeekup.render kup, context: this, locals: {rid: rid}, dynamic_locals: true)
      app.make_autoresizable container.find('textarea')

  # client side #
  # static method #
  show_edit_box: (rid) ->
    record_e = $('#'+rid)
    if record_e.find('>.contents>.edit_box_container>.edit_box').length == 0
      # get the record data
      $.ajax
        cache: false
        type: "GET"
        url: "/r/#{rid}"
        dataType: "json"
        error: ->
          console.log('meh')
        success: (data) ->
          kup = ->
            div class: "edit_box", ->
              if not data.record.parent_id
                input type: "text", name: "title", value: hE(data.record.title or '')
                br foo: 'bar'
                input type: "text", name: "url", value: hE(data.record.url or '')
                br foo: 'bar'
                textarea name: "comment", -> hE(data.record.comment or '')
              else
                textarea name: "comment", -> hE(data.record.comment or '')
              br foo: 'bar' # dunno why just br doesn't work
              button onclick: "app.post_edit('#{rid}')", -> 'update'
              button onclick: "$(this).parent().remove()", -> 'cancel'
          container = record_e.find('>.contents>.edit_box_container').
            append(coffeekup.render kup, context: this, locals: {rid: rid, data: data}, dynamic_locals: true)
          app.make_autoresizable container.find('textarea')
          container.find('input[name="title"]').set_default_text('title')
          container.find('input[name="url"]').set_default_text('URL')
          container.find('textarea[name="comment"]').set_default_text('comment')

  # client side #
  # static method #
  delete: (rid) ->
    alert 'not implemented yet'

  # client side #
  # static method #
  post_reply: (rid) ->
    record_e = $('#'+rid)
    comment = record_e.find('>.contents>.reply_box_container>.reply_box>textarea').val()
    $.ajax
      cache: false
      type: "POST"
      url: "/r/#{rid}/reply"
      data: {comment: comment}
      dataType: "json"
      error: ->
        console.log('meh')
      success: (data) ->
        if data?
          record_e.find('>.contents>.reply_box_container>.reply_box').remove()
        else
          alert 'uh oh, server might be down. try again later?'

  # client side #
  # static method #
  post_edit: (rid) ->
    record_e = $('#'+rid)
    title = record_e.find('>.contents>.edit_box_container>.edit_box>input[name="title"]').get_value()
    url = record_e.find('>.contents>.edit_box_container>.edit_box>input[name="url"]').get_value()
    comment = record_e.find('>.contents>.edit_box_container>.edit_box>textarea[name="comment"]').get_value()
    $.ajax
      cache: false
      type: "POST"
      url: "/r/#{rid}"
      data: {title: title, url: url, comment: comment}
      dataType: "json"
      error: ->
        console.log('meh')
      success: (data) ->
        if data?
          record_e.find('>.contents>.edit_box_container>.edit_box').remove()
        else
          alert 'uh oh, server might be down. try again later?'

# if server-side
if exports?
  exports.Record = Record
# if client-side
if window?
  app.Record = Record
  app.upvote = Record::upvote
  app.show_reply_box = Record::show_reply_box
  app.show_edit_box = Record::show_edit_box
  app.post_reply = Record::post_reply
  app.post_edit = Record::post_edit
