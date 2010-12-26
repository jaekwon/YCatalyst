var Db = require('mongodb').Db,
  Connection = require('mongodb').Connection,
  Server = require('mongodb').Server,
  BSON = require('mongodb').BSONNative;

var dbname = '1amendment',
    host = 'localhost',
    port = 27017;

var db = exports.db = new Db(dbname, new Server(host, port, {}), {native_parser:true});
db.open(function(err, db) {
  db.collection('records', function(err, coll) {
    exports.records = coll;
    console.log('db:records');
  });
});
