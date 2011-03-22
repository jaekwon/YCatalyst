###
# YCatalyst
# Copyright(c) 2011 Jae Kwon (jae@ycatalyst.com)
# MIT Licensed
###

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
      # The side effect of sorting here is that the dangle method will automagically sort the children by score.
      mongo.records.find {parent_id: {$in: tofetch}}, {sort: [['score', -1]]}, (err, cursor) ->
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
  object = utils.deep_clone(record.recdata)
  delete object.upvoters
  return object

# given a record, rescores the record
exports.score_record = (record) ->
  # constants
  newness_factor = 0.5 # how important is newness in hours?
  gravity = 1.8
  timebase_hours = 2.0
  # variables
  t = record.recdata.created_at.getTime()
  h = t / (60*60*1000)
  d_h = ((new Date()) - record.recdata.created_at) / (60*60*1000)
  points = record.recdata.points
  score = h*newness_factor + (points-1) / (Math.pow((d_h+timebase_hours),gravity))
  # console.log "t: #{t} h: #{h} d_h: #{d_h} points: #{points} score: #{score}"
  record.recdata.score = score

# recdata: the record data object
# parent: the data object for the parent, may be null or undefined
# returns: a new Record object
exports.create_record = (recdata, parent) ->
  parents = []
  if parent?
    if not recdata.parent_id?
      recdata.parent_id = parent.recdata._id
    if parent.recdata.parents?
      parents = [parent.recdata._id].concat(parent.recdata.parents[0..5])
    else
      parents = [parent.recdata._id]
    recdata.parent_followers = parent.recdata.followers if parent.recdata.followers
  else
    recdata.parent_id = null # need this for mongodb indexing
  if not recdata._id?
    recdata._id = utils.randid()
  recdata.created_at = new Date()
  recdata.parents = parents
  recdata.points = if recdata.upvoters then recdata.upvoters.length else 0
  record = new rec.Record(recdata)
  record.is_new = true
  exports.score_record(record)
  return record
  
# given a bunch of records and the root, organize it into a tree
# returns the root, and children can be accessed w/ .children
exports.dangle = (records, root_id) ->
  root = records[root_id]
  for id, record of records
    parent = records[record.recdata.parent_id]
    if parent
      if not parent.children
        parent.children = []
      parent.children.push(record)
  # we now have the root...
  # pull out poll items and put them in a different spot.
  if root.recdata.type == 'poll'
    orig_children = root.children
    root.children = []
    root.choices = []
    for child in orig_children
      if child.recdata.type == 'choice'
        root.choices.push(child)
      else
        root.children.push(child)
  return root

# follow or unfollow the given record...
exports.follow = (rid, user, do_follow, cb) ->
  if do_follow
    update_operation = {$addToSet: {followers: user._id}}
  else
    update_operation = {$pull: {followers: user._id}}
  mongo.records.update {_id: rid}, update_operation, cb
