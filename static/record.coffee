###
# YCatalyst
# Copyright(c) 2011 Jae Kwon (jae@ycatalyst.com)
# MIT Licensed
###

# NOTE: currently, any time we modify this file we need to ./static/compile and possibly restart the server :(

# we have to rename, otherwise coffeescript declares 'var CoffeeKup' which wipes the client side import
CoffeeKup = if window? then window.CoffeeKup else require './coffeekup'
Markz = if window? then window.Markz else require('./markz').Markz

# TODO: this is duplicate from /utils.coffee. maybe refactor into ./static/commons.
# for docs, see utils.coffee
compose = (fns...) ->
  _this = if (typeof(fns[0]) == 'function') then null else fns.shift()
  # return a function that calls the index'th function in fns
  next_gen = (index) ->
    () ->
      if not (0 <= index < fns.length)
        throw new Error "should not happen: 0 <= #{index} < #{fns.length}"
      next_block = fns[index]
      if index < fns.length - 1
        Array::unshift.call(arguments, next_gen(index+1))
      return next_block.apply(_this, arguments)
  return next_gen(0)()

# These keys extend the coffeekup DSL.
coffeekup_locals =
  Markz: Markz
  compose: compose

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
# r.recdata # {record_data}
# r.render() # <html>
#
# child = Record.create({child_data}, r)
# child.is_new # true
#
# We keep the recdata seperate from the Record, so
# as to not pollute the db fields.
# Probably a better way to handle this with prototypes :/
class Record

  # uses recdata (the persistent object) to hydrate a new Record instance.
  # if you want to add a Record to the DB, you want to call
  # logic.records.create_record()
  constructor: (recdata) ->
    @recdata = recdata
    if not @recdata.points?
      @recdata.points = 0
    if not @recdata.num_children?
      @recdata.num_children = 0
    if not @recdata.created_at?
      @recdata.created_at = new Date()
    else if typeof @recdata.created_at == 'string'
      # after JSON serialization, created_at reverts to string on client
      @recdata.created_at = new Date(@recdata.created_at)

  # initialize properties to render for a particular client.
  # options:
  #   is_root -> if true, may show 'parent' link
  #   heading_title -> the title is rendered as a heading
  #   current_user -> the user for which we are rendering the record
  set_render_options: (options) ->
    @is_root = options.is_root or false
    @heading_title = options.heading_title or false
    @current_user = options.current_user or null
    @upvoted =
      if window?
        App.upvoted.indexOf(@recdata._id) != -1
      else if @current_user
        @recdata.upvoters? and @recdata.upvoters.indexOf(@current_user._id) != -1
    @following =
      if window?
        App.following.indexOf(@recdata._id) != -1
      else if @current_user
        @recdata.followers? and @recdata.followers.indexOf(@current_user._id) != -1

  # Usage: record_instance.render("default", {})
  # See 'set_render_options' for full options.
  render: (coffeekup_name, options) ->
    throw "invalid template name #{JSON.stringify(coffeekup_name)}" if not (typeof(coffeekup_name) == "string")
    if options
      @set_render_options(options)
    coffeekup_fn = @[coffeekup_name+"_kup"] # enforce a static function for performance
    CoffeeKup.render coffeekup_fn, context: this, locals: coffeekup_locals, dynamic_locals: true

  default_kup: ->
    div class: "record", id: @recdata._id, "data-root": @is_root, "data-upvoted": @upvoted, "data-following": @following, "data-heading-title": @heading_title, ->
      if not @recdata.deleted_at?
        if @current_user
          if @recdata.created_by == @current_user.username and @recdata.type != 'choice'
            span class: "self_made", -> "*"
          else if not @upvoted
            a class: "upvote", href: '#', onclick: "Record.upvote('#{@recdata._id}'); return false;", -> "&#9650;"
        if @recdata.title
          compose (next) =>
            if @heading_title
              h1 class: "title", ->
                next()
            else
              next()
              br foo: "bar"
          , () =>
            if @recdata.url
              a href: @recdata.url, class: "title", -> @recdata.title
              if @recdata.host
                span class: "host", -> "&nbsp;(#{@recdata.host})"
            else
              a href: "/r/#{@recdata._id}", class: "title", -> @recdata.title
        span class: "item_info", ->
          span -> " #{@recdata.points or 0} pts "
          if @recdata.type != 'choice'
            text " by "
            a href: "/user/#{h(@recdata.created_by)}", -> h(@recdata.created_by)
            span -> " " + @recdata.created_at.time_ago()
            text " | "
          if @is_root and @recdata.parent_id
            a class: "parent", href: "/r/#{@recdata.parent_id}", -> "parent"
            text " | "
          if @recdata.type != 'choice'
            a class: "link", href: "/r/#{@recdata._id}", -> "link"
          if @current_user and @recdata.type != 'choice'
            text " | "
            if @following
              a class: "follow unfollow", href: "#", onclick: "Record.follow('#{@recdata._id}', false); return false;", -> "unfollow"
            else
              a class: "follow", href: "#", onclick: "Record.follow('#{@recdata._id}', true); return false;", -> "follow"
          if @current_user and @recdata.created_by == @current_user.username
            text " | "
            a class: "edit", href: "#", onclick: "Record.show_edit_box('#{@recdata._id}'); return false;", -> "edit"
            text " | "
            a class: "delete", href: "#", onclick: "Record.delete('#{@recdata._id}'); return false;", -> "delete"
        div class: "contents", ->
          # main body
          text Markz::markup(@recdata.comment) if @recdata.comment
          # perhaps some poll choices
          if @choices
            div class: "choices", ->
              for choice in @choices
                continue if choice.recdata.deleted_at?
                text choice.render("default", current_user: @current_user)
        div class: "footer", ->
          # add poll choice
          if @current_user and @recdata.type == 'poll' and @recdata.created_by == @current_user.username
            a class: "addchoice", href: "#", onclick: "Record.show_reply_box('#{@recdata._id}', {is_choice: true}); return false;", -> "add choice"
          # reply link
          if @recdata.type != 'choice'
            a class: "reply", href: "/r/#{@recdata._id}/reply", onclick: "Record.show_reply_box('#{@recdata._id}'); return false;", -> "reply"
          # placeholders
          div class: "edit_box_container"
          if @recdata.type != 'choice'
            div class: "reply_box_container"
      else
        div class: "contents deleted", -> "[deleted]"
      if @recdata.type != 'choice'
        div class: "children", ->
          if @children
            for child in @children
              text child.render("default", current_user: @current_user)
          loaded_children = if @children then @children.length else 0
          show_more_link = loaded_children < @recdata.num_children
          a class: "more #{'hidden' if not show_more_link}", href: "/r/#{@recdata._id}", ->
            span class: "number", -> "#{@recdata.num_children - loaded_children}"
            text " more replies"

  headline_kup: ->
    div class: "record", id: @recdata._id, ->
      if @current_user
        if @recdata.created_by == @current_user.username and @recdata.type != 'choice'
          span class: "self_made", -> "*"
        else if not @upvoted
          a class: "upvote", href: '#', onclick: "Record.upvote('#{@recdata._id}'); $(this).parent().find('>.item_info>.points').increment(); $(this).remove(); return false;", -> "&#9650;"
      if @recdata.url
        a href: @recdata.url, class: "title", -> @recdata.title
        if @recdata.host
          span class: "host", -> "&nbsp;(#{@recdata.host})"
      else
        a href: "/r/#{@recdata._id}", class: "title", -> @recdata.title
      br foo: "bar"
      span class: "item_info", ->
        span class: "points", -> "#{@recdata.points or 0}"
        span -> " pts by "
        a href: "/user/#{h(@recdata.created_by)}", -> h(@recdata.created_by)
        span -> " " + @recdata.created_at.time_ago()
        text " | "
        if @recdata.num_discussions
          a href: "/r/#{@recdata._id}", -> "#{@recdata.num_discussions} comments"
        else
          a href: "/r/#{@recdata._id}", -> "discuss"

  comment_url: ->
    "/r/#{@recdata._id}/reply"

  # client side #
  # update the record (which already exists in the dom)
  # this may not increment 'xyz more replies' correctly.
  # current_user: the current user XXX find better way
  redraw: (options) ->
    old = $("\##{@recdata._id}")
    choices = old.find('>.contents>.choices').detach()
    children = old.find('>.children').detach()
    options.is_root = old.attr('data-root') == 'true'
    options.heading_title = old.attr('data-heading-title') == 'true'
    old.replaceWith(this.render("default", options))
    if choices.length > 0
      $("\##{@recdata._id}").find('>.contents').append(choices)
    $("\##{@recdata._id}").find('>.children').replaceWith(children)

  # client side #
  # static method #
  # show a dialog with some challenge on it
  upvote: (rid) ->
    App.upvoted.push(rid)
    $.ajax {
      cache: false
      type: "POST"
      url: "/r/#{rid}/upvote"
      dataType: "json"
      error: ->
        console.log('meh')
      success: (data) ->
        if data and data.updates and not App.is_longpolling
          App.handle_updates data.updates
    }

  # client side #
  # static method #
  show_reply_box: (rid, options) ->
    options ||= {}
    if not App.current_user
      window.location = "/login?goto=/r/#{rid}/reply"
      return
    record_e = $('#'+rid)
    if record_e.find('>.footer>.reply_box_container>.reply_box').length == 0
      kup = ->
        div class: "reply_box", ->
          textarea name: "comment"
          br foo: 'bar' # dunno why just br doesn't work
          if @is_choice
            button onclick: "Record.post_reply('#{@rid}', 'choice')", -> 'add choice'
          else
            button onclick: "Record.post_reply('#{@rid}')", -> 'post comment'
          button onclick: "$(this).parent().remove()", -> 'cancel'
      container = record_e.find('>.footer>.reply_box_container').append(CoffeeKup.render kup, context: {rid: rid, is_choice: options.is_choice})
      container.find('textarea').make_autoresizable()

  # client side #
  # static method #
  show_edit_box: (rid) ->
    record_e = $('#'+rid)
    if record_e.find('>.footer>.edit_box_container>.edit_box').length == 0
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
              if not @data.record.parent_id
                input type: "text", name: "title", value: hE(@data.record.title or '')
                br foo: 'bar'
                input type: "text", name: "url", value: hE(@data.record.url or '')
                br foo: 'bar'
                textarea name: "comment", -> hE(@data.record.comment or '')
              else
                textarea name: "comment", -> hE(@data.record.comment or '')
              br foo: 'bar' # dunno why just br doesn't work
              button onclick: "Record.post_edit('#{@rid}')", -> 'update'
              button onclick: "$(this).parent().remove()", -> 'cancel'
          container = record_e.find('>.footer>.edit_box_container').
            append(CoffeeKup.render kup, context: {rid: rid, data: data})
          container.find('textarea').make_autoresizable()
          container.find('input[name="title"]').set_default_text('title')
          container.find('input[name="url"]').set_default_text('URL')
          container.find('textarea[name="comment"]').set_default_text('comment')

  # client side #
  # static method #
  delete: (rid) ->
    $.ajax
      cache: false
      type: "POST"
      url: "/r/#{rid}/delete"
      datatype: "json"
      error: ->
        console.log('meh')
      success: (data) ->
        console.log('deleted')

  # client side #
  # static method #
  post_reply: (rid, type) ->
    record_e = $('#'+rid)
    comment = record_e.find('>.footer>.reply_box_container>.reply_box>textarea').val()
    $.ajax
      cache: false
      type: "POST"
      url: "/r/#{rid}/reply"
      data: {comment: comment, type: type}
      dataType: "json"
      error: ->
        console.log('meh')
      success: (data) ->
        if data?
          record_e.find('>.footer>.reply_box_container>.reply_box').remove()
          if data.updates and not App.is_longpolling
            App.handle_updates data.updates
        else
          alert 'uh oh, server might be down. try again later?'

  # client side #
  # static method #
  post_edit: (rid) ->
    record_e = $('#'+rid)
    title = record_e.find('>.footer>.edit_box_container>.edit_box>input[name="title"]').get_value()
    url = record_e.find('>.footer>.edit_box_container>.edit_box>input[name="url"]').get_value()
    comment = record_e.find('>.footer>.edit_box_container>.edit_box>textarea[name="comment"]').get_value()
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
          record_e.find('>.footer>.edit_box_container>.edit_box').remove()
          if data.updates and not App.is_longpolling
            App.handle_updates data.updates
        else
          alert 'uh oh, server might be down. try again later?'

  # client side #
  # static method #
  # do_follow: false means unfollow, otherwise should be true
  follow: (rid, do_follow) ->
    record_e = $('#'+rid)
    $.ajax
      cache: false
      type: "POST"
      url: "/r/#{rid}/follow"
      data: {follow: do_follow}
      dataType: "json"
      error: ->
        console.log('meh')
      success: (data) ->
        if data?
          if do_follow
            App.following.push rid
            record_e
              .attr('data-following', true)
              .find('>.item_info>.follow')
                .addClass('unfollow')
                .unbind('click')
                .attr('onclick', null)
                .click( (event) -> Record.follow(rid, false); false )
                .text('unfollow')
          else
            App.following = (x for x in App.following when x != rid)
            record_e
              .attr('data-following', false)
              .find('>.item_info>.follow')
                .removeClass('unfollow')
                .unbind('click')
                .attr('onclick', null)
                .click( (event) -> Record.follow(rid, true); false )
                .text('follow')
        else
          alert 'uh oh, server might be down. try again later?'

# if server-side
if exports?
  exports.Record = Record
# if client-side
if window?
  window.Record = Record
  Record.upvote = Record::upvote
  Record.follow = Record::follow
  Record.show_reply_box = Record::show_reply_box
  Record.show_edit_box = Record::show_edit_box
  Record.post_reply = Record::post_reply
  Record.post_edit = Record::post_edit
  Record.delete = Record::delete
