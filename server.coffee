require.paths.unshift 'vendor/jade'
require.paths.unshift 'vendor/sherpa/lib'

http = require 'http'
jade = require 'jade'
sherpa = require 'sherpa/nodejs'
utils = require './utils'
mongo = require './mongo'
fu = require './fu'
underscore = require './static/underscore'
rec = require('./static/record')

DEFAULT_DEPTH = 5

#if false
#  process.on 'uncaughtException', (err) ->
#    console.log "XXX HOLY SHIT"
#    console.log err
#    console.log "FIX THIS ASAP, http://debuggable.com/posts/node-js-dealing-with-uncaught-exceptions:4c933d54-1428-443c-928d-4e1ecbdd56cb"

get_records = (root_id, level, fn) ->
  mongo.records.findOne _id: root_id, (err, root) ->
    all = {}
    all[root_id] = new rec.Record(root)
    tofetch = [root_id]
    fetchmore = (i) ->
      # NOTE: http://talklikeaduck.denhaven2.com/2009/04/15/ordered-hashes-in-ruby-1-9-and-javascript
      # and   http://ejohn.org/blog/javascript-in-chrome/
      # The side effect of sorting here is that the record.coffe/dangle method will automagically sort the children by points.
      mongo.records.find {parent_id: {$in: tofetch}}, {sort: [['points', -1]]}, (err, cursor) ->
        cursor.toArray (err, records) ->
          tofetch = []
          for record in records
            tofetch.push(record._id)
            all[record._id] = new rec.Record(record)
          if i > 1
            fetchmore(i-1)
          else
            fn(all)
    fetchmore(level)

get_one_record = (rid, fn) ->
  mongo.records.findOne _id: rid, (err, recdata) ->
    if recdata
      fn(new rec.Record(recdata))
    else
      fn(null)

# a global hash from record id to [callbacks]
all_callbacks = {}

# given a record, tell clients that this record had been updated
# -> if record is new
# -> if record was deleted
# -> if record got voted on
# 
# TODO we need to keep track of more state
trigger_update = (record) ->
  if record.object.upvoters?
    delete record.object.upvoters
  if record.is_new
    notify_keys = record.object.parents or []
  else
    notify_keys = [record.object._id].concat (record.object.parents or [])
  for key in notify_keys
    for callback in all_callbacks[key] or []
      callback([record])
    delete all_callbacks[key]

http.createServer(utils.Rowt(new Sherpa.NodeJs([

  ['/static/:filepath', (req, res) ->
    switch req.method
      when 'GET'
        filepath = req.sherpaResponse.params.filepath
        filepath = require('path').join './static/', filepath
        if filepath.indexOf('static/') != 0
          res.writeHead 404, 'does not exist'
          res.end()
        else
          fu.staticHandler(filepath)(req, res)
  ]

  ['/', (req, res) ->
    switch req.method
      when 'GET'
        mongo.records.find (err, cursor) ->
          cursor.toArray (err, records) ->
            records = (new rec.Record(record) for record in records)
            res.writeHead 200, status: 'ok'
            jade.renderFile 'templates/index.jade', locals: {records: records, require: require}, (err, html) ->
              if err
                console.log err
              res.end html
      when 'POST'
        parent_id = req.post_data.parent_id
        comment = req.post_data.comment
        data = parent_id: parent_id, _id: utils.randid(), comment: comment
        if parent_id
          mongo.records.findOne _id: parent_id, (err, item) ->
            if err
              console.log err
            else
              # good, it exists!
              mongo.records.save data, (err, stuff) ->
                res.writeHead 302, Location: '/r/'+stuff._id
                res.end()
        else
          console.log 'no parent? wheres ur dad?'
  ]

  ['/r/:id', (req, res) ->
    switch req.method
      when 'GET'
        root_id = req.sherpaResponse.params.id
        get_records root_id, DEFAULT_DEPTH, (all) ->
          jade.renderFile 'templates/record.jade', locals: {root: rec.dangle(all, root_id), require: require}, (err, html) ->
            console.log err if err
            res.writeHead 200, status: 'ok'
            res.end html
  ],

  ['/r/:id/reply', (req, res) ->
    switch req.method
      when 'GET'
        parent_id = req.sherpaResponse.params.id
        get_one_record parent_id, (parent) ->
          jade.renderFile 'templates/reply.jade', locals: {parent: parent, require: require}, (err, html) ->
            console.log err if err
            res.writeHead 200, status: 'ok'
            res.end html
      when 'POST'
        parent_id = req.sherpaResponse.params.id
        comment = req.post_data.comment
        get_one_record parent_id, (parent) ->
          if parent
            data = parent_id: parent_id, _id: utils.randid(), comment: comment
            record = rec.Record::create(data, parent)
            mongo.records.save record.object, (err, stuff) ->
              res.writeHead 302, Location: '/r/'+parent_id
              res.end()
              # notify clients
              trigger_update record
          else
            res.writeHead 404, status: 'error'
            res.end html
  ],

  ['/r/:key/recv', (req, res) ->
    switch req.method
      when 'GET'
        key = req.sherpaResponse.params.key
        if not all_callbacks[key]
          all_callbacks[key] = []
        all_callbacks[key].push (records) ->
          res.simpleJSON(200, (r.object for r in records))
        console.log(all_callbacks)
  ],

  ['/r/:id/upvote', (req, res) ->
    switch req.method
      when 'POST'
        rid = req.sherpaResponse.params.id
        get_one_record rid, (record) ->
          if not record.object.upvoters?
            record.object.upvoters = []
          if record.object.upvoters.indexOf('XXX') == -1
            record.object.upvoters.push('XXX')
          record.object.points = record.object.upvoters.length
          mongo.records.save record.object, (err, stuff) ->
            res.simpleJSON(200, status: 'ok', recdata: record.object)
  ]

]).listener())).listen 8124, '127.0.0.1'

console.log 'Server running at http://127..0.1:8124'
