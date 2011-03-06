Db = require('mongodb').Db
Connection = require('mongodb').Connection
Server = require('mongodb').Server
BSON = require('mongodb').BSONNative

dbname = 'glyphtree'
host = 'localhost'
port = 27017

# keep list of callbacks to call after database opens. {name -> [callbacks]}
open_callbacks = {}
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

db_info = {
  'records': [
      [['parent_id', 1], ['score', 1]]]
  'users': [
      [['email', 1]]],
  'invites': [
      [['user_id', 1]]],
  'diffbot': [
      [['guid', 1]]]
  'diffbot_subscriptions': null
  'app': null
}

db = exports.db = new Db(dbname, new Server(host, port, {}), {native_parser: true})
db.open (err, db) ->
  for name, indices of db_info
    db.collection name, (err, coll) ->
      for index of indices
        coll.ensureIndex index, (err, indexName) ->
          console.log "created index: #{indexName}"
    did_open(name)
