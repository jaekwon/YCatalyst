Db = require('mongodb').Db
Connection = require('mongodb').Connection
Server = require('mongodb').Server
BSON = require('mongodb').BSONNative

dbname = 'glyphtree'
host = 'localhost'
port = 27017

open_callbacks = {} # keep list of callbacks to call after database opens. {name -> [callbacks]}
did_open = (name, coll) ->
  console.log("did_open #{name}")
  #console.log exports
  exports[name] = coll
  if open_callbacks[name]?
    for callback in open_callbacks[name]
      callback()
# call this function to queue a callback that requires a db collection as soon as the app opens
exports.after_open = (name, cb) ->
  if exports[name]?
    cb()
  else
    if open_callbacks[name]?
      open_callbacks[name].push(cb)
    else
      open_callbacks[name] = [cb]

db = exports.db = new Db(dbname, new Server(host, port, {}), {native_parser: true})
db.open (err, db) ->

  # set up records
  db.collection 'records', (err, coll) ->
    coll.ensureIndex [['parent_id', 1], ['score', 1]], (err, indexName) ->
      console.log "created index: #{indexName}"
      #coll.indexInformation (err, doc) ->
      #  console.log "information: #{require('sys').inspect(doc)}"
    did_open('records', coll)

  # set up users
  db.collection 'users', (err, coll) ->
    coll.ensureIndex [['email', 1]], (err, indexName) ->
      console.log "created index: #{indexName}"
    did_open('users', coll)

  # set up invites
  db.collection 'invites', (err, coll) ->
    coll.ensureIndex [['user_id', 1]], (err, indexName) ->
      console.log "created index: #{indexName}"
    did_open('invites', coll)

  # set up app stuff
  db.collection 'app', (err, coll) ->
    did_open('app', coll)

  # set up diffbot pubsub stuff
  db.collection 'diffbot', (err, coll) ->
    coll.ensureIndex [['guid', 1]], (err, indexName) ->
      console.log "created index: #{indexName}"
    did_open('diffbot', coll)
