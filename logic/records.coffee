mongo = require '../mongo'
utils = require '../utils'
rec = require '../static/record'

exports.get_records = (root_id, level, fn) ->
  now = new Date()
  mongo.records.findOne _id: root_id, (err, root) ->
    all = {}
    if not root?
      fn(err, null)
      return
    all[root_id] = new rec.Record(root)
    tofetch = [root_id]
    fetchmore = (i) ->
      # NOTE: http://talklikeaduck.denhaven2.com/2009/04/15/ordered-hashes-in-ruby-1-9-and-javascript
      # and   http://ejohn.org/blog/javascript-in-chrome/
      # The side effect of sorting here is that the dangle method will automagically sort the children by points.
      mongo.records.find {parent_id: {$in: tofetch}}, {sort: [['points', -1]]}, (err, cursor) ->
        cursor.toArray (err, records) ->
          tofetch = []
          for record in records
            tofetch.push(record._id)
            all[record._id] = new rec.Record(record)
          if i > 1
            fetchmore(i-1)
          else
            console.log "get_records in #{new Date() - now}"
            fn(err, all)
    fetchmore(level)

exports.get_one_record = (rid, fn) ->
  mongo.records.findOne _id: rid, (err, recdata) ->
    if recdata
      fn(err, new rec.Record(recdata))
    else
      fn(err, null)

# given a record object, return an object we can return to the client
# any time you need to send a record to the client through ajax, 
# scrub it here
exports.scrubbed_recdata = (record) ->
  object = utils.deep_clone(record.object)
  delete object.upvoters
  return object

# recdata: the record data object
# parent: the data object for the parent
# returns: a new Record object
exports.create_record = (recdata, parent) ->
  parents = []
  if parent?
    if not recdata.parent_id?
      recdata.parent_id = parent.object._id
    if parent.object.parents?
      parents = [parent.object._id].concat(parent.object.parents[0..5])
    else
      parents = [parent.object._id]
  if not recdata._id?
    recdata._id = utils.randid()
  recdata.created_at = new Date()
  recdata.parents = parents
  record = new rec.Record(recdata)
  record.is_new = true
  return record
  
# given a bunch of records and the root, organize it into a tree
# returns the root, and children can be accessed w/ .children
exports.dangle = (records, root_id) ->
  root = records[root_id]
  for id, record of records
    parent = records[record.object.parent_id]
    if parent
      if not parent.children
        parent.children = []
      parent.children.push(record)
  return root
