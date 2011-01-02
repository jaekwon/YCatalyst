# currently, any time we modify this file we need to ./static/compile and possibly restart the server :(

# we have to rename, otherwise coffeescript declares 'var CoffeeKup' which wipes the client side import
coffeekup = if CoffeeKup? then CoffeeKup else require 'coffeekup'
app = if window? then window.app else require '../app'

# usage: 
# r = new Record({record_data})
# r.object # {record_data}
# r.render() # <html>
#
# child = Record.create({child_data}, r)
# child.is_new # true
class Record
  constructor: (object) ->
    @object = object
    if not @object.points?
      @object.points = 0
    if not @object.num_children?
      @object.num_children = 0

  render_kup: ->
    div class: "record", id: @object._id, "data-parents": JSON.stringify(@object.parents), "data-root": is_root, ->
      span class: "top_items", ->
        if not hide_upvote
          a class: "upvote", href: '#', onclick: "app.upvote('#{h(@object._id)}'); return false;", -> "&spades;"
        span -> " #{@object.points or 0} pts"
        text " | "
        if is_root and @object.parent_id
          a class: "parent", href: "/r/#{@object.parent_id}", -> "parent"
          text " | "
        a class: "link", href: "/r/#{@object._id}", -> "link"
      p ->
        text h(@object.comment)
        text " "
        a class: "reply", href: "/r/#{@object._id}/reply", -> "reply"
      div class: "children", ->
        if @children
          for child in @children
            text child.render(is_root: false)
        loaded_children = if @children then @children.length else 0
        if loaded_children < @object.num_children
          a class: "more", href: "/r/#{@object._id}", -> "#{@object.num_children - loaded_children} more replies"

  # options:
  #   is_root -> default true, if false, doesn't show parent_link,
  #   hide_upvote -> default false, if true, doesn't show the upvote button. 
  render: (options) ->
    is_root = not options? or options.is_root
    hide_upvote = options?.hide_upvote
    if @object.upvoters? and @object.upvoters.indexOf(app.current_user) != -1
      hide_upvote = true
    coffeekup.render @render_kup, context: this, locals: {is_root: is_root, hide_upvote: hide_upvote}, dynamic_locals: true

  comment_url: ->
    "/r/#{@object._id}/reply"

  # static method #
  # recdata: the record data object
  # parent: the data object for the parent
  create: (recdata, parent) ->
    parents = []
    if parent?
      if parent.object.parents?
        parents = [parent.object._id].concat(parent.object.parents[0..5])
      else
        parents = [parent.object._id]
    recdata.parents = parents
    record = new Record(recdata)
    record.is_new = true
    return record

  # client side #
  # update the record (which already exists in the dom)
  redraw: (options) ->
    old = $("\##{@object._id}")
    old_is_root = old.attr('data-root') == "true"
    children = old.find('.children:eq(0)').detach()
    options.is_root = old_is_root
    old.replaceWith(this.render(options))
    $("\##{@object._id}").find('.children:eq(0)').replaceWith(children)

# given a bunch of records and the root, organize it into a tree
# returns the root, and children can be accessed w/ .children
dangle = (records, root_id) ->
  root = records[root_id]
  for id, record of records
    parent = records[record.object.parent_id]
    if parent
      if not parent.children
        parent.children = []
      parent.children.push(record)
  return root

# if server-side
if exports?
  exports.Record = Record
  exports.dangle = dangle
# if client-side
if window?
  if not window.app?
    window.app = {}
  window.app.Record = Record
  window.app.dangle = dangle
