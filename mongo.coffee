###
# YCatalyst
# Copyright(c) 2011 Jae Kwon (jae@ycatalyst.com)
# MIT Licensed
###

Db = require('mongodb').Db
Connection = require('mongodb').Connection
Server = require('mongodb').Server
BSON = require('mongodb').BSONNative
config = require('./config')

# keep list of callbacks to call after database opens. {name -> [callbacks]}
open_callbacks = {}
did_open = (name, coll) ->
  console.log("did_open #{name}")
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
      [['email', 1]]]
  'invites': [
      [['user_id', 1]]]
  'referrals': [
      [['email', 1]]]
  'applications': null
  'messages': null
  'diffbot': [
      [['guid', 1]]]
  'diffbot_subscriptions': null
  'app': null
}

db = exports.db = new Db(config.mongo.dbname, new Server(config.mongo.host, config.mongo.port, {}), {native_parser: true})
db.open (err, db) ->
  for name, indices of db_info
    db.collection name, (err, coll) ->
      if indices
        for index in indices
          coll.ensureIndex index, (err, indexName) ->
            console.log "ensured index: #{indexName}"
      # TODO should call did_open after all indices are ensured, with callback chaining of sorts.
      did_open(name, coll)
