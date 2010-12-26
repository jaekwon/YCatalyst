require.paths.unshift('vendor/jade');
require.paths.unshift('vendor/sherpa/lib');

var http = require('http');
var jade = require('jade');
var sherpa = require('sherpa/nodejs');
var utils = require('./utils');
var mongo = require('./mongo');

// [{'type': 'div', 'attr': {}, 'contents': []]
// {'type', 'id', 'attr', 'contents', 'style', 'script'}

http.createServer(utils.Rowt(new Sherpa.NodeJs([

  ['/', function (req, res) {
    if (req.method == 'GET') {
      mongo.records.find(function(err, cursor) {
        cursor.toArray(function(err, records) {
          res.writeHead(200, {'status': 'ok'});
          jade.renderFile('templates/index.jade', {locals: {records: records}}, function(err, html) {
            if (err) {
              console.log(err);
            }
            res.end(html);
          });
        });
      });
    } else if (req.method == 'POST') {
      var data = JSON.parse(req.post_data.data),
          target_id = req.post_data.id;
      data._id = utils.randid();
      if (target_id) {
        mongo.records.findOne({'_id': target_id}, function(err, item) {
          if (item.contents == undefined) {
            item.contents = [];
          }
          item.contents.push(data);
          mongo.records.save(item, function(err, stuff) {
            res.writeHead(302, {'Location': '/'});
            res.end();
          });
        });
      } else {
        mongo.records.insert(data, function(data) {
          res.writeHead(302, {'Location': '/'});
          res.end();
        });
      }
    }
  }],

  ['/dev', function (req, res) {
    if (req.method == 'POST') {
      try {
        res.writeHead(200, {'status': 'ok'});
        var result = 
          eval(req.post_data.command);
        res.end(JSON.stringify({'result': result}));
      } catch(e) {
        res.writeHead(400, {'status': 'error'});
        var result = ''+e;
        res.end(JSON.stringify({'error': result}));
      }
    } else if (req.method == 'GET') {
    }
  }],

  ['/e/:name', function (req, res) {
  }],
]).listener())).listen(8124, "127.0.0.1");

console.log('Server running at http://127.0.0.1:8124/');
