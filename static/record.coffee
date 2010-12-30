# currently, any time we modify this file we need to ./static/compile and possibly restart the server :(

# er, move this out
escape = hE = (html) ->
  String(html)
    .replace(/&(?!\w+;)/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')

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

  # options:
  #   is_root -> default true, if false, doesn't show parent_link,
  render: (options) ->
    is_root = not options? or options.is_root
    lines = []
    top_links = []
    data_parents = []
    if is_root
      data_parents = "data-parents=\"#{hE(JSON.stringify(@object.parents))}\""
    if is_root and @object.parent_id
      top_links.push("""<a href="/r/#{@object.parent_id}" class="parent">parent</a>""")
    top_links.push("""<a href="/r/#{@object._id}" class="link">link</a>""")
    top_links.push("""#{hE(JSON.stringify(@object.parents))}""")

    lines.push("""<span class="top_links">#{top_links.join(" | ")}</span>""")
    lines.push("""<p>#{hE(@object.comment)}</p>""")
    lines.push("""
      <a href="/r/#{@object._id}/reply" class="reply">reply</a>
      """)
    # children?
    lines.push("""<div class="children">""")
    if @children
      (lines.push(child.render(is_root: false)) for child in @children)
    lines.push("""</div>""")
    # record
    """<div class="record" id="#{@object._id}" #{data_parents} #{'data-root="true"' if is_root}>
        #{lines.join("\n")}
      </div>"""

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
