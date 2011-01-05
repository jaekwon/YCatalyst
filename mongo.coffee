Db = require('mongodb').Db
Connection = require('mongodb').Connection
Server = require('mongodb').Server
BSON = require('mongodb').BSONNative

dbname = '1amendment'
host = 'localhost'
port = 27017

db = exports.db = new Db(dbname, new Server(host, port, {}), {native_parser: true})
db.open (err, db) ->

  # set up records
  db.collection 'records', (err, coll) ->
    exports.records = coll
    console.log('db:records')
    # ensure indexes
    coll.ensureIndex [['parent_id', 1], ['points', 1]], (err, indexName) ->
      console.log "created index: #{indexName}"
      #coll.indexInformation (err, doc) ->
      #  console.log "information: #{require('sys').inspect(doc)}"

  # set up users
  db.collection 'users', (err, coll) ->
    exports.users = coll
    console.log('db:users')

  # set up invites
  db.collection 'invites', (err, coll) ->
    exports.invites = coll
    console.log('db:invites')
    # ensure indexes
    coll.ensureIndex [['user_id', 1]], (err, indexName) ->
      console.log "created index: #{indexName}"
